//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ParityTaxHook
 * @author ParityTax Team
 * @notice Main hook contract implementing Uniswap V4's hook system for equitable fee distribution
 * @dev This contract manages liquidity commitments, fee collection, and tax distribution between JIT and PLP providers
 * @dev The _afterRemoveLiquidity function is heavily inspired by LiquidityPenaltyHook.sol from OpenZeppelin Uniswap Hooks
 */

//=================================================================
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {LiquidityAmounts} from "@uniswap/v4-periphery/src/libraries/LiquidityAmounts.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "@uniswap/v4-core/src/libraries/TransientStateLibrary.sol";
//=========================================================================

import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {PositionConfig} from "@uniswap/v4-periphery/test/shared/PositionConfig.sol";
//==================================================================

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


//======================================================================
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";
import {V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";
import {QuoterRevert} from "@uniswap/v4-periphery/src/libraries/QuoterRevert.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "@uniswap/v4-periphery/lib/permit2/src/interfaces/IAllowanceTransfer.sol";
//============================================================================
import "./interfaces/IParityTaxHook.sol";
import "./types/Shared.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import "./base/ParityTaxHookBase.sol";
import {IParityTaxExtt} from "./interfaces/IParityTaxExtt.sol";
//===================================================================


// ======================== Currency Related Imports==================================
import{
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
// import {DeltaResolver} from "@uniswap/v4-periphery/src/base/DeltaResolver.sol";
import {CurrencyDelta} from "@uniswap/v4-core/src/libraries/CurrencyDelta.sol";

// =============== External Dependencies ============================
import {
    FeeRevenueInfo,
    FeeRevenueInfoLibrary
} from "./types/FeeRevenueInfo.sol";
import {
    SwapIntent,
    SwapIntentLibrary
} from "./types/SwapIntent.sol";
//TODO: Do we need a manager also for the PLP ?? ...

import {ILiquidityMetrics} from "./interfaces/ILiquidityMetrics.sol";

//logging-Debugging

import {console2} from "forge-std/Test.sol";

contract ParityTaxHook is IParityTaxHook, ParityTaxHookBase{
    using SafeCast for *;
    using FeeRevenueInfoLibrary for *;
    using SwapIntentLibrary for *;
    using Position for address;
    using Address for address;
    using QuoterRevert for bytes;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencySettler for Currency;
    using CurrencyDelta for Currency;
    

    /**
     * @notice Initializes the ParityTaxHook with required dependencies
     * @dev Sets up the pool manager, position manager, LP oracle, and ParityTaxExtt for hook operations
     * @param _poolManager The Uniswap V4 pool manager contract
     * @param _lpm The position manager for liquidity operations
     * @param _lpOracle Oracle for liquidity price information
     * @param _parityTaxExtt The ParityTaxExtt contract for transient storage operations
     * @dev WARNING: The ParityTaxRouter is not needed as any router that calls the swap/modifyLiquidity
     * with the right hookData and no claims is valid
     */
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        ILPOracle _lpOracle,
        IParityTaxExtt _parityTaxExtt
    ) ParityTaxHookBase(
        _poolManager,
        _lpm,
        _lpOracle,
        _parityTaxExtt
        ) 
    {

    }

    /**
     * @notice Handles pre-initialization logic for new pools
     * @dev WARNING: Here the deployer sets governance that can update the fiscal policy tax calculation
     * and also manager oracle dependencies initialization
     */
    function _beforeInitialize(
        address,
        PoolKey calldata,
        uint160) internal virtual override returns (bytes4) {
            return IHooks.beforeInitialize.selector;
    }


    /**
     * @notice Executes before swap logic including JIT liquidity addition and price tracking
     * @dev Handles JIT liquidity provision and stores pre-swap price data for accurate tracking
     * @dev All this data is passed to the JIT Resolver, which returns the JIT liquidity that is willing to fulfill
     * @dev This is to be improved to store beforeSwap prices on transient storage and emit the event on afterSwap for further accuracy
     * @dev WARNING: This is a placeholder implementation. Correct calculation needs to be done for PLP liquidity determination
     */
    function _beforeSwap(
        address swapRouter ,
        PoolKey calldata poolKey, 
        SwapParams calldata swapParams,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24)
    {   
        PoolId poolId = poolKey.toId();        
        SwapContext memory swapContext = abi.decode(hookData, (SwapContext));

        // Store pre-swap prices in transient storage for afterSwap processing
        {
            _tstore_swap_beforeSwapSqrtPriceX96(swapContext.beforeSwapSqrtPriceX96);
            _tstore_swap_beforeSwapExternalSqrtPriceX96(swapContext.beforeSwapSqrtPriceX96);
        }

        if (
            Currency.unwrap(swapContext.poolKey.currency0) != Currency.unwrap(poolKey.currency0) ||
            Currency.unwrap(swapContext.poolKey.currency1) != Currency.unwrap(poolKey.currency1)
        ) revert CurrencyMissmatch();
        
        bool isExactInput = swapContext.swapParams.amountSpecified <0;

        // Add JIT liquidity through resolver
        (uint256 jitPositionTokenId,uint256 jitLiquidity) = jitResolver.addLiquidity(
            swapContext
        );

        uint128 totalLiquidity = poolManager.getLiquidity(poolId);
        {
            _tstore_jit_tokenId(jitPositionTokenId);    
        }

    
        

        PositionInfo jitPositionInfo = _tload_jit_positionInfo();

        uint128 plpLiquidity = totalLiquidity - uint128(jitLiquidity);

        emit LiquidityOnSwap(
            PoolId.unwrap(poolId),
            uint48(block.number),
            totalLiquidity,
            uint128(jitLiquidity),
            plpLiquidity
        );
         


        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, uint24(0x00));
    }
    


    /**
     * @notice Handles post-swap operations including JIT liquidity removal and fee collection
     * @dev Processes JIT liquidity removal, calculates fee revenue, and remits to fiscal policy
     * @dev WARNING: This is a placeholder implementation for external price calculation
     * @dev WARNING: This is to be improved to include the actual converted external price
     * @dev WARNING: The JIT fee revenue has been earned on the asset losing appreciation. This needs to be corrected so it converts to a numeraire
     */
    function _afterSwap(
        address swapRouter,
        PoolKey calldata poolKey,
        SwapParams calldata swapParams,
        BalanceDelta swapDelta,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, int128)
    {

        //=====================COMMON-BASE=====================//
        PoolId poolId = poolKey.toId();
        (uint160 afterSwapSqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) = poolManager.getSlot0(poolId);
      
        (uint160 beforeSwapSqrtPriceX96, uint160 beforeSwapExternalSqrtPriceX96) = (
            _tload_swap_beforeSwapSqrtPriceX96(),
            _tload_swap_beforeSwapExternalSqrtPriceX96()
        );
        uint160 afterSwapExternalSqrtPriceX96 = afterSwapSqrtPriceX96;

        //======================================================
        // =====================JIT============================//
        uint256 jitTokenId = _tload_jit_tokenId();
        console2.log("JIT Token ID:", jitTokenId);
        
        if (jitTokenId > uint256(0x00)){

            emit PriceImpact(
                PoolId.unwrap(poolId),
                uint48(block.number),
                swapParams.zeroForOne.swapIntent(swapParams.amountSpecified < 0),
                swapDelta,
                beforeSwapSqrtPriceX96,
                beforeSwapExternalSqrtPriceX96,
                afterSwapSqrtPriceX96,
                afterSwapExternalSqrtPriceX96 
            );
            LiquidityPosition memory _jitLiquidityPosition = getLiquidityPosition(
                poolKey,
                LP_TYPE.JIT,
                address(jitResolver),
                jitTokenId
            );

            
            _tstore_jit_liquidityPosition(_jitLiquidityPosition);
            
            if(_jitLiquidityPosition.liquidity > uint256(0x00)){
                jitResolver.removeLiquidity(_jitLiquidityPosition);
                LiquidityPosition memory jitLiquidityPosition = _tload_jit_liquidityPosition();
                FeeRevenueInfo jitFeeRevenueInfo = uint48(block.number).init(
                    JIT_COMMITMENT,
                    uint80(jitLiquidityPosition.feeRevenueOnCurrency0),
                    uint80(jitLiquidityPosition.feeRevenueOnCurrency1)
                );

                fiscalPolicy.remit(
                    poolId,
                    jitFeeRevenueInfo
                    
                );

                emit Remittance(
                    PoolId.unwrap(poolId),
                    uint48(block.number),
                    JIT_COMMITMENT,
                    jitFeeRevenueInfo.toBalanceDelta()
                );


            }
        }
        //====================================================//


        return (IHooks.afterSwap.selector, int128(0x00));
    }

    /**
     * @notice Manages liquidity addition with commitment validation and JIT/PLP routing
     * @dev Handles both JIT and PLP liquidity commitments based on hook data and current state
     * @dev This applies for hooks where the user provides valid hookData. This needs to be considered
     */
    function _beforeAddLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        bytes calldata hookData
    ) internal virtual override onlyPositionManagerForJIT(liquidityRouter) returns (bytes4)
    {
        
        //===========================COMMON-BASE===========================//
        (PoolId poolId, bytes32 lpPositionKey) = _getPoolIdAndPositionKey(
            liquidityRouter,
            poolKey,
            liquidityParams
        );
        //=================================================================
        
        
        //NOTE: This applies for hooks where the user puts valid hookData. This needs to be considered 
        uint256 jitTokenId = _tload_jit_tokenId();

        
        Commitment memory jitCommitment = Commitment({
            committer: address(jitResolver),
            blockNumberCommitment: JIT_COMMITMENT
        });

        Commitment memory plpCommitment;
        
        if (hookData.length == COMMITMENT_LENGTH){
            
            Commitment memory lpCommitment = abi.decode(
                hookData,
                (Commitment)
            );



            if (lpCommitment.blockNumberCommitment >= MIN_PLP_BLOCK_NUMBER_COMMITMENT && jitTokenId == uint256(0x00)){
                plpCommitment = lpCommitment;  
                uint48 plpBlockNumberCommitment = plpCommitment.blockNumberCommitment + uint48(block.number);
                lpCommitment.blockNumberCommitment = plpBlockNumberCommitment;
            
                uint256 plpPositionTokenId = plpResolver.commitLiquidity(
                    poolKey,
                    liquidityParams,
                    plpCommitment.committer,
                    plpBlockNumberCommitment
                );
                _tstore_plp_tokenId(plpPositionTokenId);
        
                _lockLiquidity(
                    poolId,
                    plpPositionTokenId,
                    plpCommitment.committer,
                    plpBlockNumberCommitment
                );
            
                
                emit LiquidityCommitted(
                    PoolId.unwrap(poolId),
                    uint48(block.number),
                    lpCommitment.blockNumberCommitment,
                    lpCommitment.committer,
                    plpPositionTokenId,
                    abi.encode(liquidityParams)
                );



            } else if (jitTokenId > uint256(0x00)) {

                if (address(liquidityRouter) != address(lpm)){
                    revert InvalidLiquidityRouterCaller();
                }


                lpCommitment = jitCommitment;
                
                emit LiquidityCommitted(
                    PoolId.unwrap(poolId),
                    uint48(block.number),
                    lpCommitment.blockNumberCommitment,
                    lpCommitment.committer,
                    jitTokenId,
                    abi.encode(liquidityParams)
                );

            } else if (jitTokenId == uint256(0x00) && lpCommitment.blockNumberCommitment < MIN_PLP_BLOCK_NUMBER_COMMITMENT){
                revert InvalidPLPBlockCommitment();
            }




        }
        //==================================================================//
        
        return IHooks.beforeAddLiquidity.selector;
    }

    

    /**
     * @notice Handles post-liquidity addition fee collection and remittance
     * @dev Processes PLP fee revenue and remits to fiscal policy, stores JIT fee revenue in transient storage
     * @dev This needs to be the position manager associated with the liquidity operator
     */
    function _afterAddLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        BalanceDelta,
        BalanceDelta feeDelta,
        bytes calldata hookData
    ) internal virtual override onlyPositionManagerForJIT(liquidityRouter) returns (bytes4, BalanceDelta) {
        //===========================COMMON-BASE===========================//
        (PoolId poolId, bytes32 lpPositionKey) = _getPoolIdAndPositionKey(
            liquidityRouter,
            poolKey,
            liquidityParams
        );
        //=================================================================
 
        //==========================PLP==============================//
        if (hookData.length == COMMITMENT_LENGTH){
            
            Commitment memory plpCommitment = abi.decode(
                hookData,
                (Commitment)
            );
            uint256 plpPositionTokenId = _tload_plp_tokenId();

            FeeRevenueInfo plpFeeRevenueInfo = uint48(block.number).init(
                plpCommitment.blockNumberCommitment + uint48(block.number),
                uint80(int80(feeDelta.amount0())),
                uint80(int80(feeDelta.amount1()))
            );

            console2.log("Fiscal Policy Address:", address(fiscalPolicy));

            fiscalPolicy.remit(
                poolId,
                plpFeeRevenueInfo
                
            );

            emit Remittance(
                PoolId.unwrap(poolId),
                uint48(block.number),
                plpCommitment.blockNumberCommitment + uint48(block.number),
                plpFeeRevenueInfo.toBalanceDelta()
            );




        }
        //==========================================================//


        //=========================JIT=================================
        uint256 jitTokenId = _tload_jit_tokenId();
        
        if (jitTokenId > uint256(0x00)){
            _tstore_jit_feeRevenue(
                uint256(feeDelta.amount0().toUint128()), 
                uint256(feeDelta.amount1().toUint128())
            );
        }
        
        //==========================================================//

        return (IHooks.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }



    /**
     * @notice Validates liquidity removal permissions and commitment compliance
     * @dev Handles PLP liquidity removal validation and commitment expiration checks
     */
    function _beforeRemoveLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        bytes calldata hookData
    )
    internal
    virtual 
    override
    onlyPositionManager(liquidityRouter)
    returns (bytes4)
    {
         //===========================COMMON-BASE===========================//
        (PoolId poolId, bytes32 lpPositionKey) = _getPoolIdAndPositionKey(
            liquidityRouter,
            poolKey,
            liquidityParams
        );
        //=============================================PLP========================================================//
        //============================REMOVING FROM POSITION MANAGER=====================================
        if (uint256(liquidityParams.salt) > uint256(0x00) && _tload_jit_tokenId() == uint256(0x00)){
            uint256 tokenId = uint256(liquidityParams.salt);
            address positionOwner = abi.decode(
                address(lpm).functionStaticCall(
                    abi.encodeWithSignature(
                        "ownerOf(uint256)",
                        tokenId
                    )   
                ),
                (address)
            );
            assert(tokenId == _tload_plp_tokenId());
            uint48 lpLiquidityCommitment = getPositionBlockNumberCommitment(
                poolId,
                positionOwner,
                tokenId
            );

            if (uint48(block.number) < lpLiquidityCommitment) {
                revert NotWithdrawableLiquidity__LiquidityIsCommitted();
            }
            
            plpResolver.removeLiquidity(
                poolId,
                tokenId,
                liquidityParams.liquidityDelta
            );

            _clearPositionBlockNumberCommitment(
                poolId,
                positionOwner, 
                tokenId
            );
                
        }
 
             
        //=================================================================================
        //===============================JIT===============================================


        //=================================================================================
        
        
        return IHooks.beforeRemoveLiquidity.selector;
    }




    /**
     * @notice Handles post-liquidity removal operations and fee processing
     * @dev Processes JIT fee revenue and handles tax calculations for liquidity removal
     * @dev This tokenId is just for internal reference because the positionManager burns the position before modifyingLiquidity
     * @dev This informs the tax controller what kind of LP this is
     * @dev If there is a tax liability to be applied but there are no active liquidity positions in range to receive the donation, then the liquidity removal is not possible and the offset must be awaited
     * @dev WARNING: This is where accrueCredit gets called and assigns the right rewards to PLPs based on their commitment
     */
    function _afterRemoveLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        BalanceDelta,
        BalanceDelta feeRevenueDelta,
        bytes calldata
    ) internal virtual override onlyPositionManager(liquidityRouter) returns (bytes4, BalanceDelta) {
        
    
        //=============================PLP===================================//


        // BalanceDelta withheldFees = _remitFeeRevenue(poolKey, ,plpPositionTokenId);

        // BalanceDelta taxableFeeRevenueIncomeDelta = feeRevenueDelta + withheldFees;

        // if (withheldFees != BalanceDeltaLibrary.ZERO_DELTA) {
        //     BalanceDelta returnDelta = toBalanceDelta(-withheldFees.amount0(), -withheldFees.amount1());
        //     return (this.afterRemoveLiquidity.selector, returnDelta);
        // }
        // //=================================================================//
        
        // //============================JIT=================================//
        // //NOTE: This tokenId is just for internal reference becasue the positionManager
        // // burns the position before modifyingLiquidity
        uint256 jitTokenId = _tload_jit_tokenId();
        
        if (jitTokenId > uint256(0x00)){        
            _tstore_jit_feeRevenue(
                uint256(feeRevenueDelta.amount0().toUint128()), 
                uint256(feeRevenueDelta.amount1().toUint128())
            );
        }

        // if (jitLiquidityPosition.liquidity > uint256(0x00)){
        // //NOTE: This informs the tax controller what kind of LP this is
        //     fiscalPolicy.fillJITTaxReturn(taxableFeeRevenueIncomeDelta, JIT_COMMITMNET);
        //     BalanceDelta jitTaxLiabilityDelta = fiscalPolicy.getJitTaxLiability(taxableFeeRevenueIncomeDelta);
            
        //     //NOTE If there is a tax liability to be applied but there are no active liquidity positions in range to
        //     // receive the donation, then the liquidity removal is not possible and the offset must be awaited.
        //     if (poolManager.getLiquidity(poolId) == 0) revert NoLiquidityToReceiveTaxCredit();
        //     poolManager.donate(
        //         poolKey,
        //         uint256(int256(jitTaxLiabilityDelta.amount0())),
        //         uint256(int256(jitTaxLiabilityDelta.amount1())),
        //         Constants.ZERO_BYTES
        //     );

        //     return (IHooks.afterRemoveLiquidity.selector, jitTaxLiabilityDelta - withheldFees); 
        // }

        return (IHooks.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
 
    }


    /**
     * @notice Handles post-donation operations for credit accrual and PLP rewards
     * @dev Processes donations and assigns rewards to PLPs based on their commitment
     * @dev WARNING: This is where accrueCredit gets called and assigns the right rewards to PLPs based on their commitment
     */
    function _afterDonate(
        address, 
        PoolKey calldata,
        uint256,
        uint256, 
        bytes calldata
    ) internal virtual override returns (bytes4){
        return IHooks.afterDonate.selector;
    }

    /**
     * @notice Returns the ParityTaxExtt instance for transient storage operations
     * @dev This allows external contracts to access the transient storage through ParityTaxExtt
     * @return The ParityTaxExtt contract instance
     */
    function getParityTaxExtt() external view returns (IParityTaxExtt) {
        return parityTaxExtt;
    }





}


