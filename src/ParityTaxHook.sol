//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
// import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {LiquidityAmounts} from "@uniswap/v4-periphery/src/libraries/LiquidityAmounts.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "@uniswap/v4-core/src/libraries/TransientStateLibrary.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";
import {QuoterRevert} from "@uniswap/v4-periphery/src/libraries/QuoterRevert.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "@uniswap/v4-periphery/lib/permit2/src/interfaces/IAllowanceTransfer.sol";

import {ILPOracle} from "./interfaces/ILPOracle.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {ITaxController} from "./interfaces/ITaxController.sol";
import {V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";

import {PositionInfoLibrary, PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";


// ======================== Currency Related Imports==================================
import{
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
// import {DeltaResolver} from "@uniswap/v4-periphery/src/base/DeltaResolver.sol";
import {CurrencyDelta} from "@uniswap/v4-core/src/libraries/CurrencyDelta.sol";

// =============== External Dependencies ============================
//TODO: Do we need a manager also for the PLP ?? ...
import {IPLPOperator} from "./interfaces/IPLPOperator.sol";
import {IJITHub} from "./interfaces/IJITHub.sol";
import {IParityTaxRouter} from "./interfaces/IParityTaxRouter.sol";
import {IParityTaxHook} from "./interfaces/IParityTaxHook.sol";
import {ParityTaxHookBase} from "./base/ParityTaxHookBase.sol";
import "./types/Shared.sol";


//logging-Debugging

import {console2} from "forge-std/Test.sol";

contract ParityTaxHook is IParityTaxHook, ParityTaxHookBase, BaseHook{
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
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencySettler for Currency;
    using CurrencyDelta for Currency;
    

    IParityTaxRouter router;
    IJITHub jitHub;
    IPLPOperator plpOperator;
    ILPOracle lpOracle;
    ITaxController taxController;




    constructor(
        IPoolManager _manager,
        address _router,
        address _jitHub,
        address _plpOperator,
        address _lpOracle,
        address _taxController
    ) BaseHook(_manager) {
        router = IParityTaxRouter(_router);
        jitHub = IJITHub(_jitHub);
        plpOperator = IPLPOperator(_plpOperator);
        lpOracle = ILPOracle(_lpOracle);
        taxController = ITaxController(_taxController);
    }





    modifier onlyUncommitedLiquidity(
        PoolId poolId,
        uint256 plpTokenId
    ){
        uint48 plpCommitment = plpOperator.getPLPCommitment(
            poolId,
            bytes32(plpTokenId)
        );
        if (plpCommitment !=0 && block.number < plpCommitment ) revert NotWithdrawableLiquidity__LiquidityIsCommitted(uint256(plpCommitment)-block.number);   
        _;
    }


    function getHookPermissions() public pure virtual override returns (Hooks.Permissions memory){
        return Hooks.Permissions({
            beforeInitialize: true, // This permission is to sync the internal price with the external one
            afterInitialize: false,  
            beforeAddLiquidity: true, // Handles the commitment of PLP's and JIT's 
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: true,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta:true,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: true,
            afterRemoveLiquidityReturnDelta: true
        });
    }

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
        // a bool response acknoleding the amount willing to fulfill
                
        JITData memory jitData = abi.decode(hookData, (JITData));
        
        if (
            jitData.token0 != Currency.unwrap(poolKey.currency0) ||
            jitData.token1 != Currency.unwrap(poolKey.currency1)
        ) revert CurrencyMissmatch();
        
        bool isExactInput = jitData.amountSpecified <0;
        // NOTE: The JITHub mints the liquidity to fill the swap

        (uint256 jitLiquidity, uint256 positionTokenId) = IJITHub(
            address(jitHub)
        ).addLiquidity(
            jitData
        );

        tstore_JIT_liquidity(jitLiquidity);
        tstore_JIT_positionKey(bytes32(positionTokenId));


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
        (uint256 jitLiquidity,uint256 jitPositionTokenId) = (
            tload_JIT_addedLiquidity(),
            uint256(tload_JIT_positionKey())
        );

        // NOTE: If both values are positve this is a swap
        // fulfilled by JIT's
        if (jitLiquidity >0 && jitPositionTokenId > 0){
            IJITHub(address(jitHub)).removeLiquidity(
                jitPositionTokenId
            );
        }
        return (IHooks.afterSwap.selector, int128(0x00));
    }

    function _beforeAddLiquidity(
        address,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) internal virtual override returns (bytes4)
    {
        if (hookData.length >0)
        {
            
            {
                //============PLP==============
            
                address(plpOperator).functionCall(hookData);
                //If success the PLP commits its liquidity
            }
        }   
        
        return IHooks.beforeAddLiquidity.selector;
    }

    function _afterAddLiquidity(
        address sender, //This needs to be the posm associated with the liquidity operator
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata liquidityParams,
        BalanceDelta,
        BalanceDelta feeDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, BalanceDelta) {
        
        // PositionInfo jitPositionInfo = _jitPositionInfo();
        // bytes32 lpPositionKey = sender.calculatePositionKey(
        //         liquidityParams.tickLower,
        //         liquidityParams.tickUpper,
        //         liquidityParams.salt            
        //     );
        // uint256 jitLiquidity = tload_JIT_addedLiquidity();
        // JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        // {
        //     // =====================JIT=======================
        //     if (jitLiquidity > 0){
        //         jitTransientMetrics.positionKey = lpPositionKey;
        //         jitTransientMetrics.withheldFees = _withheldFees() + feeDelta;
        //         poolKey.currency0.take(
        //             poolManager, 
        //             address(this),
        //             uint256(uint128(feeDelta.amount0())),
        //             true
        //         );
        //         poolKey.currency1.take(
        //             poolManager,
        //             address(this),
        //             uint256(uint128(feeDelta.amount1())),
        //             true
        //         );

        //     }else {
        //         jitTransientMetrics.positionKey = bytes32(uint256(0x00));
        //     }

        // }
        {

            //===================PLP=================
            // NOTE: The owners
        }

        return (IHooks.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
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
    onlyUncommitedLiquidity
    (
        poolKey.toId(),
        uint256(sender.calculatePositionKey(
                liquidityParams.tickLower,
                liquidityParams.tickUpper,
                liquidityParams.salt            
            ))
    ) returns (bytes4)
    {
        return IHooks.beforeRemoveLiquidity.selector;
    }


    function _afterRemoveLiquidity(
        address,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta feeRevenueDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, BalanceDelta) {
        PoolId poolId = poolKey.toId();
        bytes32 jitPositionKey = tload_JIT_positionKey();
        {
            //===================JIT========================
            if (jitPositionKey != bytes32(uint256(0x00))){
                BalanceDelta initialFeeDelta = BalanceDelta.wrap(_withheldFees());
                if (initialFeeDelta.amount0() > 0){
                    poolKey.currency0.settle(
                        poolManager,
                        address(this),
                        uint256(uint128(initialFeeDelta.amount0())),
                        true
                    );
                }

                if (initialFeeDelta.amount1() > 0){
                    poolKey.currency1.settle(
                        poolManager,
                        address(this),
                        uint256(uint128(initialFeeDelta.amount1())),
                        true
                    );
                }

                BalanceDelta totalFees = feeRevenueDelta + initialFeeDelta;
                if (
                    totalFees != BalanceDeltaLibrary.ZERO_DELTA
                )
                {
                    BalanceDelta taxedDelta = taxController.taxJITFeeRevenue(
                        totalFees
                    );
                    if (poolManager.getLiquidity(poolId) == 0) revert NoLiquidityToReceiveTaxRevenue();
                
                    // TODO: taxedDelta is to be taked by the taxController
                
                    // poolManager.donate(
                    //     poolKey, 
                    //     uint256(int256(taxedDelta.amount0())), 
                    //     uint256(int256(taxedDelta.amount1())),
                    //     Constants.ZERO_BYTES
                    // );
                    
                }

            }
            // TODO: Here we calculate the JIT lp profit and store it on the tsMetrics
            // then any other calls on the same transaction are governed by the hookData
            // TODO: Here also we must calculate the JIT cummProfit
        }
        return (IHooks.afterRemoveLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
 
    }


    // function getSqrtPriceImpactX96() public view returns(uint160[] memory){
    //     return metrics.sqrtPriceImpactX96;
    // }


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


