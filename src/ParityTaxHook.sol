//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//=================================================================
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {TickPacking} from "./libraries/TickPacking.sol";
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
import {IParityTaxHook} from "./interfaces/IParityTaxHook.sol";
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
//TODO: Do we need a manager also for the PLP ?? ...



//logging-Debugging

import {console2} from "forge-std/Test.sol";

contract ParityTaxHook is IParityTaxHook, ParityTaxHookBase{
    using Position for address;
    using Address for address;
    using QuoterRevert for bytes;
    using SafeCast for *;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using TickPacking for int24;
    using TickPacking for bytes32;
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencySettler for Currency;
    using CurrencyDelta for Currency;
    

    mapping(PoolId poolId => mapping(uint256 tokenId => uint48 blockNumberCommitment)) private _plpBlockNumberCommitmnet;
    mapping(PoolId poolId => mapping(bytes32 positionKey => BalanceDelta delta)) private _withheldFees;


    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IJITResolver _jitResolver,
        IPLPResolver _plpResolver,
        IParityTaxRouter _parityTaxRouter,
        ITaxController _taxController,
        ILPOracle _lpOracle
    ) ParityTaxHookBase(
        _poolManager,
        _lpm,
        _jitResolver,
        _plpResolver,
        _parityTaxRouter,
        _taxController,
        _lpOracle
        ) 
    {

    }





    // modifier onlyUncommitedLiquidity(
    //     PoolId poolId,
    //     uint256 plpTokenId
    // ){
    //     uint48 plpCommitment = plpOperator.getPLPCommitment(
    //         poolId,
    //         bytes32(plpTokenId)
    //     );
    //     if (plpCommitment !=0 && block.number < plpCommitment ) revert NotWithdrawableLiquidity__LiquidityIsCommitted(uint256(plpCommitment)-block.number);   
    //     _;
    // }


    function _beforeInitialize(
        address,
        PoolKey calldata,
        uint160) internal virtual override returns (bytes4) {
            return IHooks.beforeInitialize.selector;
    }


// ===================================================================================================
//                  "Intent: How much of currency1 can I buy given a specified amount of currency0"
//    "Trader deposits currency0 "             "Trader enters 0"            "Trader receives currency1"   
//    swapParams.amountSpecified < 0     ^         zeroForOne         -->     amountUnspecified > 0
//
//                "Intent: How much of currency0 can I buy given a specified amount of currency1"
//    "Trader deposits currency1"               "Trader enters 1"         "Trader receives currency0"
//     swapParams.amountSpecified < 0      ^       !zeroForOne        -->   amountUnspecified > 0
//
//                "Intent: How much currency0 must I sell to receive a specified amount of currency1"
//     swapParams.amountSpecified > 0     ^        zeroForOne        -->   amountUnspecified < 0
//
//                "Intent: How much currency1 must I sell to receive a specified amount of currency0"
//     swapParams.amountSpecified > 0     ^        !zeroForOne       -->   amountUnspecified < 0
// ====================================================================================================

    function _beforeSwap(
        address swapRouter ,
        PoolKey calldata poolKey, 
        SwapParams calldata swapParams,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24)
    {   
        //NOTE: All this data is passed to the JIT Hub, which returns
        // a bool response acknoledging the amount willing to fulfill
                
        JITData memory jitData = abi.decode(hookData, (JITData));
        
        if (
            jitData.token0 != Currency.unwrap(poolKey.currency0) ||
            jitData.token1 != Currency.unwrap(poolKey.currency1)
        ) revert CurrencyMissmatch();
        
        bool isExactInput = jitData.amountSpecified <0;
        // NOTE: The JITHub mints the liquidity to fill the swap

        uint256 jitPositionTokenId = jitResolver.addLiquidity(
            jitData
        );

        assembly("memory-safe"){
            tstore(JIT_LIQUIDITY_LOCATION, jitPositionTokenId)
        }


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

        // =====================JIT=======================
        
        (uint256 jitLiquidity, uint256 jitPositionTokenId) = _getJitPositionTokenIdAndLiquidity();

        if (jitLiquidity > uint256(0x00)){
            jitResolver.removeLiquidity(jitPositionTokenId);
        }
        //=================================================


        return (IHooks.afterSwap.selector, int128(0x00));
    }

    function _beforeAddLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        bytes calldata hookData
    ) internal virtual override returns (bytes4)
    {
        
        PoolId poolId = poolKey.toId();
        

        //NOTE: This means that there is a time commitment, thus is a PLP position 
        if (hookData.length >0)
        {
            
            uint48 plpBlockNumberCommitment = abi.decode(
                hookData,
                (uint48)
            ) + uint48(block.timestamp);
            
            uint256 plpPositionTokenId = plpResolver.commitLiquidity(
                poolId,
                liquidityParams,
                plpBlockNumberCommitment
            );

            _lockLiquidity(poolId, plpPositionTokenId, plpBlockNumberCommitment);

            
        }   
        
        return IHooks.beforeAddLiquidity.selector;
    }

    function _lockLiquidity(
        PoolId poolId,
        uint256 tokenId,
        uint48 blockNumberCommitment
    ) private {
        _plpBlockNumberCommitmnet[poolId][tokenId] =blockNumberCommitment; 
    }

    function _afterAddLiquidity(
        address sender, //This needs to be the posm associated with the liquidity operator
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        BalanceDelta,
        BalanceDelta feeDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, BalanceDelta) {
        PoolId poolId = poolKey.toId();
        bytes32 lpPositionKey = sender.calculatePositionKey(
            liquidityParams.tickLower,
            liquidityParams.tickUpper,
            liquidityParams.salt
        );

        

        _withholdFeeRevenue(poolKey,lpPositionKey,feeDelta);

        

        return (IHooks.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function _withholdFeeRevenue(
        PoolKey memory poolKey,
        bytes32 lpPositionKey,
        BalanceDelta feeRevenueDelta
    ) internal virtual {
        PoolId poolId = poolKey.toId();
         _withheldFees[poolId][lpPositionKey] = _withheldFees[poolId][lpPositionKey] + feeRevenueDelta;

        poolKey.currency0.take(poolManager, address(this), uint256(uint128(feeRevenueDelta.amount0())), true);
        poolKey.currency1.take(poolManager, address(this), uint256(uint128(feeRevenueDelta.amount1())), true);
    }

    function _beforeRemoveLiquidity(
        address sender,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        bytes calldata
    )
    internal
    virtual 
    override
    returns (bytes4)
    {
        PoolId poolId = poolKey.toId();
        bytes32 lpPositionKey = sender.calculatePositionKey(
            liquidityParams.tickLower,
            liquidityParams.tickUpper,
            liquidityParams.salt
        );

        uint48 plpPositionBlockNumberCommitment = getPositionBlockNumberCommitment(
            poolId ,
            lpPositionKey
        );

        if (uint48(block.number) >= plpPositionBlockNumberCommitment ){
            _clearPositionBlockNumberCommitment(poolId, lpPositionKey);
            plpResolver.removeLiquidity(
                poolId,
                lpPositionKey,
                liquidityParams.liquidityDelta
            );
        } else if (
            plpPositionBlockNumberCommitment != uint48(0x00) 
            &&
            uint48(block.number) < plpPositionBlockNumberCommitment
        )
        {
            uint48 remainingCommitment = plpPositionBlockNumberCommitment - uint48(block.number);
            revert NotWithdrawableLiquidity__LiquidityIsCommitted(remainingCommitment);
        }
        
        
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function getPositionBlockNumberCommitment(
        PoolId poolId,
        uint256 tokenId
    ) public view returns(uint48){
        return _plpBlockNumberCommitmnet[poolId][tokenId];
    }

    function _clearPositionBlockNumberCommitment(
        PoolId poolId,
        uint256 tokenId
    ) private{
        _plpBlockNumberCommitmnet[poolId][tokenId] = uint48(0x00);
    }


    function _afterRemoveLiquidity(
        address sender,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        BalanceDelta,
        BalanceDelta feeRevenueDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, BalanceDelta) {
        PoolId poolId = poolKey.toId();
        
        bytes32 lpPositionKey = sender.calculatePositionKey(
            liquidityParams.tickLower,
            liquidityParams.tickUpper,
            liquidityParams.salt
        );

        BalanceDelta withheldFees = _remitFeeRevenue(poolKey, lpPositionKey);

        BalanceDelta taxableFeeRevenueIncomeDelta = feeRevenueDelta + withheldFees;
        

        //=============================JIT========================================
        (uint256 jitLiquidity, uint256 jitPositionTokenId) = _getJitPositionTokenIdAndLiquidity();
    
        //NOTE: This is sufficient condition to tell this transaction
        // is JIT Liquidity
        
        if (jitLiquidity > uint256(0x00)){
            //NOTE: This informs the tax controller what kind of LP this is
            taxController.fillJITTaxReturn(taxableFeeRevenueIncomeDelta, JIT_COMMITMNET);
            BalanceDelta jitTaxLiabilityDelta = taxController.getJitTaxLiability(taxableFeeRevenueIncomeDelta);
            
            //NOTE If there is a tax liability to be applied but there are no active liquidity positions in range to
            // receive the donation, then the liquidity removal is not possible and the offset must be awaited.
            if (poolManager.getLiquidity(poolId) == 0) revert NoLiquidityToReceiveTaxCredit();
            poolManager.donate(
                poolKey,
                uint256(int256(jitTaxLiabilityDelta.amount0())),
                uint256(int256(jitTaxLiabilityDelta.amount1())),
                Constants.ZERO_BYTES
            );

           return (IHooks.afterRemoveLiquidity.selector, jitTaxLiabilityDelta - withheldFees); 

            
        }


        //==========================PLP=============================================
        // If the liquidity removal was not penalized, return the withheld fees if any.
        if (withheldFees != BalanceDeltaLibrary.ZERO_DELTA) {
            BalanceDelta returnDelta = toBalanceDelta(-withheldFees.amount0(), -withheldFees.amount1());
            return (this.afterRemoveLiquidity.selector, returnDelta);
        }
        

        
        
        return (IHooks.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
 
    }

    function _remitFeeRevenue(
        PoolKey memory poolKey,
        bytes32 lpPositionKey
    ) internal virtual returns(BalanceDelta withheldFees) {
        
        PoolId poolId = poolKey.toId();
        
        withheldFees = getWithheldFees(poolId, lpPositionKey);
        
        _withheldFees[poolId][lpPositionKey] = BalanceDeltaLibrary.ZERO_DELTA;

        if (withheldFees.amount0() > 0) {
            poolKey.currency0.settle(poolManager, address(this), uint256(uint128(withheldFees.amount0())), true);
        }
        if (withheldFees.amount1() > 0) {
            poolKey.currency1.settle(poolManager, address(this), uint256(uint128(withheldFees.amount1())), true);
        }

    }


    // function getSqrtPriceImpactX96() public view returns(uint160[] memory){
    //     return metrics.sqrtPriceImpactX96;
    // }

    function getWithheldFees(PoolId poolId, bytes32 positionKey) public view virtual returns (BalanceDelta) {
        return _withheldFees[poolId][positionKey];
    }


    //TODO: This is a place holder, to be implemented
    function getCurrentPrice() public view returns(uint256){
        return 1;
    }

    // function approvePosmCurrency(
    //     Currency currency,
    //     uint256 amount, 
    //     uint48 expiration
    // ) internal {
    //     // Because POSM uses permit2, we must execute 2 permits/approvals.
    //     // 1. First, the caller must approve permit2 on the token.
    //     address permit2 = jitOperator.permit2();
    //     IERC20(Currency.unwrap(currency)).approve(permit2, type(uint256).max);
    //     // 2. Then, the caller must approve POSM as a spender of permit2. TODO: This could also be a signature.
    //     IAllowanceTransfer(permit2).approve(Currency.unwrap(currency), address(jitOperator.positionManager()), type(uint160).max, expiration);
    // }




}


