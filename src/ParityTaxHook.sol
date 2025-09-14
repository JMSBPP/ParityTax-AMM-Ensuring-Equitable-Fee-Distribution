//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    


    //TODO: The ParityTaxRouter is not needed as any router that calls the swap/modifyLiquidity
    // with the right hookData and no claims is valid
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        ITaxController _taxController,
        ILPOracle _lpOracle
    ) ParityTaxHookBase(
        _poolManager,
        _lpm,
        _taxController,
        _lpOracle
        ) 
    {

    }



    function _beforeInitialize(
        address,
        PoolKey calldata,
        uint160) internal virtual override returns (bytes4) {
            return IHooks.beforeInitialize.selector;
    }




    function _beforeSwap(
        address swapRouter ,
        PoolKey calldata poolKey, 
        SwapParams calldata swapParams,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24)
    {   
        //NOTE: All this data is passed to the JIT Hub, which returns
        // a bool response acknoledging the amount willing to fulfill
        PoolId poolId = poolKey.toId();        
        SwapContext memory swapContext = abi.decode(hookData, (SwapContext));
        // NOTE: This is to be improved to it stores beforeSwap prices on TS
        // and emits the event on afterSwap for further accuracy

        // on afterSwapPrices
        _tstore_swap_beforeSwapSqrtPriceX96(swapContext.beforeSwapSqrtPriceX96);
        _tstore_swap_beforeSwapExternalSqrtPriceX96(swapContext.beforeSwapSqrtPriceX96);

        if (
            Currency.unwrap(swapContext.poolKey.currency0) != Currency.unwrap(poolKey.currency0) ||
            Currency.unwrap(swapContext.poolKey.currency1) != Currency.unwrap(poolKey.currency1)
        ) revert CurrencyMissmatch();
        
        bool isExactInput = swapContext.swapParams.amountSpecified <0;
        // NOTE: The JITHub mints the liquidity to fill the swap

        (uint256 jitPositionTokenId,uint256 jitLiquidity) = jitResolver.addLiquidity(
            swapContext
        );

        uint128 totalLiquidity = poolManager.getLiquidity(poolId);

        
        _tstore_jit_tokenId(jitPositionTokenId);

        PositionInfo jitPositionInfo = _tload_jit_positionInfo();

        // uint128 plpLiquidity =  uint128(taxController.router().getSwapPLPLiquidity(
        //     poolKey,
        //     jitPositionInfo.tickLower(),
        //     jitPositionInfo.tickUpper() 
        // ));
        // TODO: This is a place holder, correct calculation needs to be done 
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
        // TODO : This is a place holder
        uint160 afterSwapExternalSqrtPriceX96 = afterSwapSqrtPriceX96;

        //======================================================
        // =====================JIT============================//
        uint256 jitTokenId = _tload_jit_tokenId();
        
        if (jitTokenId > uint256(0x00)){

            emit PriceImpact(
                PoolId.unwrap(poolId),
                uint48(block.number),
                swapParams.zeroForOne.swapIntent(swapParams.amountSpecified < 0),
                swapDelta,
                beforeSwapSqrtPriceX96,
                beforeSwapExternalSqrtPriceX96, //TODO: This is to be imporoved to include the actual converted external price
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
                //TODO: The jit fee reevenue has been earned on the asset losing appreciation
                // this needs to be corrected so it converts to a numeraire 
                FeeRevenueInfo jitFeeRevenueInfo = uint48(block.number).init(
                    JIT_COMMITMENT,
                    uint80(jitLiquidityPosition.feeRevenueOnCurrency0),
                    uint80(jitLiquidityPosition.feeRevenueOnCurrency1)
                );

                taxController.filTaxReport(
                    poolKey,
                    jitFeeRevenueInfo
                );


            }
        }
        //====================================================//


        return (IHooks.afterSwap.selector, int128(0x00));
    }

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

    

    function _afterAddLiquidity(
        address liquidityRouter, //This needs to be the posm associated with the liquidity operator
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

            _withholdFeeRevenue(poolKey,plpCommitment.committer,plpPositionTokenId,feeDelta);
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
        if (uint256(liquidityParams.salt) > uint256(0x00)){
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
        // uint256 jitTokenId = _tload_jit_tokenId();
        
        // if (jitTokenId > uint256(0x00)){        
        //     _tstore_jit_feeRevenue(
        //         uint256(feeRevenueDelta.amount0().toUint128()), 
        //         uint256(feeRevenueDelta.amount1().toUint128())
        //     );
        // }

        // if (jitLiquidityPosition.liquidity > uint256(0x00)){
        // //NOTE: This informs the tax controller what kind of LP this is
        //     taxController.fillJITTaxReturn(taxableFeeRevenueIncomeDelta, JIT_COMMITMNET);
        //     BalanceDelta jitTaxLiabilityDelta = taxController.getJitTaxLiability(taxableFeeRevenueIncomeDelta);
            
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





}


