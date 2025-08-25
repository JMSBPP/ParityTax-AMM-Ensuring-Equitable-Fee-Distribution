// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta,BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
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
import {IPLPOperator} from "./interfaces/IPLPOperator.sol";
import {IJITOperator} from "./interfaces/IJITOperator.sol";
import {ILPOracle} from "./interfaces/ILPOracle.sol";
import {ITaxController} from "./interfaces/ITaxController.sol";
import {V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";

import {PositionInfoLibrary, PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";
import{
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";

//logging-Debugging

import {console2} from "forge-std/Test.sol";

contract ParityTaxHook is BaseHook {
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
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencySettler for Currency;
    
    /// @custom:transient-storage-location erc7201:openzeppelin.transient-storage.JIT_TRANSIENT
    struct JIT_Transient_Metrics{
        //slot1 
        uint128 addedLiquidity;
        uint128 jitProfit;
        // slot2 
        PositionInfo jitPositionInfo;
        // slot3 
        bytes32 positionKey;
        // slot4 
        BalanceDelta withheldFees;
          // slot5

        
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant JIT_Transient_MetricsLocation = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;

    function _jitTransientMetrics() private view returns(JIT_Transient_Metrics memory){
        bytes32 slot1;
        bytes32 slot2;
        bytes32 slot3;
        bytes32 slot4;
        assembly("memory-safe"){
            slot1 := tload(JIT_Transient_MetricsLocation)
            slot2 := tload(add(JIT_Transient_MetricsLocation, 0x01))
            slot3 := tload(add(JIT_Transient_MetricsLocation, 0x02))
            slot4 := tload(add(JIT_Transient_MetricsLocation, 0x03))
        }
        // Unpack the struct
        return JIT_Transient_Metrics({
            addedLiquidity: uint128(uint256(slot1)),
            jitProfit: uint128(uint256(slot1 >> 128)),
            jitPositionInfo: PositionInfo.wrap(uint256(slot2)),
            positionKey: slot3,
            withheldFees : BalanceDelta.wrap(uint256(slot4).toInt256())
        });
    }

    function _addedLiquidity() private view returns(uint128){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.addedLiquidity;
    }

    function _jitProfit() private view returns(uint128){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.jitProfit;
    }

    function _jitPositionInfo() private view returns(PositionInfo){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.jitPositionInfo;
    }

    function _jitPositionKey() private view returns(bytes32){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.positionKey;
    }

    function _withheldFees() private view returns(BalanceDelta){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.withheldFees;
    }

    /// @custom:storage-location erc7201:openzeppelin.storage.JIT_Aggregate_Metrics
    struct JIT_Aggregate_Metrics{
        uint256 cummAddedLiquidity;
        uint256 cummProfit;
    }


    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.JIT_AGGREGATE")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant JIT_Aggregate_MetricsLocation = 0xe0cf99b8cd0560d8640e62178018c84af9084dd2b92a0b03d3120e8fa0633800;

    function _getJITAggregateMetrics() private pure returns (JIT_Aggregate_Metrics storage $){
        assembly{
            $.slot := JIT_Aggregate_MetricsLocation
        }
    }




    IV4Quoter v4Quoter;
    IJITOperator jitOperator;
    IPLPOperator plpOperator;
    ILPOracle lpOracle;
    ITaxController taxController;

    error NotEnoughLiquidity(PoolId poolId);
    error NotWithdrawableLiquidity__LiquidityIsCommitted(uint256 remainingCommitedBlocks);
    error NoLiquidityToReceiveTaxRevenue();


    constructor(
        IPoolManager _manager,
        address _v4Quoter,
        address _jitOperator,
        address _plpOperator,
        address _lpOracle,
        address _taxController
    ) BaseHook(_manager){
        v4Quoter = IV4Quoter(_v4Quoter);
        jitOperator = IJITOperator(_jitOperator);
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
            beforeSwapReturnDelta:false,
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



    // ============================DEBUGGING LOGS (EVENTS) ====================

    event ImportantMetricsLog(
        int24 beforeSwapTick,
        int24 expectedAfterSwapTick, //This is to be compared with the actualAfterSwapTick to asses the 
        // accuracy of the calculation
        uint160 expectedSqrtPriceImpactX96,
        BalanceDelta expectedSwapDelta, // This is to be comparaed with the actualSwapDelta on afterSwap
        // to asses the accuracy of the calculation
        uint128 plpLiquidityBeforeSwap,
        uint128 plpLiquidityAfterSwap,
        int256 jitLiquidityUsedOnTrade
    );

    event HypotheticalProfitabilityConditions(
        uint24 lpFee,
        uint160 expectedSqrtPriceImpactX96,
        bool isProfitable,
        uint160 feeTimes2
    );

    //       =========================================================
    // NOTE: For this Hook the bytes hookData is to implement further calls

    // before the transaction ends

    function _beforeSwap(
        address,
        PoolKey calldata poolKey, 
        SwapParams calldata swapParams,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24)
    {   
        // NOTE: store the price before the swap
        (uint160 beforeSwapSqrtPriceX96,int24 beforeSwapTick,,uint24 lpFee) = poolManager.getSlot0(poolKey.toId());
        uint160 expectedSqrtPriceImpactX96;
        int256 jitLiquidityDelta;
        int24 expectedAfterSwapTick;
        {
            // NOTE: This is to get the expectedPrice Impact and also calculate a good 
            // bound for the tick range where liquidity will be provided
            bool isExactInput = swapParams.amountSpecified <0;
            bool zeroForOne = swapParams.zeroForOne;
            //NOTE: THE IV4Quoter.quoteExact<Input/Output>Single tries to unlock the poolManager
            // which is already unlocked at this point. Then we need to do low-level call
            
            // However the quoter requreis that the _quoteExact<Input/Output>Single can only 
            // by called by himselff
            // Then we need to replicate the function here:
            BalanceDelta swapDelta = BalanceDelta.wrap(
                abi.decode(
                    address(poolManager).functionCall(
                        abi.encodeCall(
                            IPoolManager.swap,
                            (
                                poolKey,
                                swapParams,
                                Constants.ZERO_BYTES
                            )
                        )
                    ),
                    (int256)
                )
            );
            
            uint256 amountSpecified = isExactInput ? zeroForOne ? uint128(swapDelta.amount1()) : uint128(swapDelta.amount0()) : zeroForOne ? uint128(-swapDelta.amount0()) : uint128(-swapDelta.amount1());
            
            {
                console2.log("Expected Trade Output: ", amountSpecified);
            }

            uint128 plpLiquidity = poolManager.getLiquidity(poolKey.toId());
            
            uint160 expectedAfterSwapSqrtPriceX96 = isExactInput ? beforeSwapSqrtPriceX96.getNextSqrtPriceFromOutput(
                plpLiquidity,
                amountSpecified,
                zeroForOne
            ) : beforeSwapSqrtPriceX96.getNextSqrtPriceFromInput(
                plpLiquidity,
                amountSpecified,
                zeroForOne
            );
            expectedSqrtPriceImpactX96 = beforeSwapSqrtPriceX96 > expectedAfterSwapSqrtPriceX96 ? beforeSwapSqrtPriceX96 - expectedAfterSwapSqrtPriceX96 : expectedAfterSwapSqrtPriceX96 - beforeSwapSqrtPriceX96;  
            expectedAfterSwapTick = expectedAfterSwapSqrtPriceX96.getTickAtSqrtPrice();
        
            //NOTE: This is to determine the jitLiquidityDelta to provide at such price range
            // based on the expected (simulated trade)

            {
                jitLiquidityDelta = int128(
                beforeSwapSqrtPriceX96.getLiquidityForAmounts(
                    beforeSwapSqrtPriceX96,
                    expectedAfterSwapTick.getSqrtPriceAtTick(),
                    uint256(swapDelta.amount0().toUint128()),
                    uint256(swapDelta.amount1().toUint128())
                ).toInt256());
            //=================FOR DEBUGGING =============
                emit ImportantMetricsLog(
                    beforeSwapTick,
                    expectedAfterSwapTick,
                    expectedSqrtPriceImpactX96,
                    swapDelta,
                    poolManager.getLiquidity(poolKey.toId()),
                    uint128(0x00), // This is to be used on afterSwap
                    jitLiquidityDelta
                );
            }

            emit HypotheticalProfitabilityConditions(
                lpFee,
                expectedSqrtPriceImpactX96,
                uint160(0x02)*uint160(lpFee) >= expectedSqrtPriceImpactX96,
                uint160(0x02)*uint160(lpFee)
            );
        }

        


        // ===================================================
        //TODO: This can is to be potentially modified by sophisticated checkings, 
        // but initially based on the JIT paper
        
        if (uint160(0x02)*uint160(lpFee) >= expectedSqrtPriceImpactX96){
            // TODO: This is to be improved using the positionManager
            jitOperator.addJITLiquidity(
                poolKey,
                beforeSwapTick,
                expectedAfterSwapTick,
                jitLiquidityDelta.toInt128().toUint128(),
                address(taxController),
                hookData
            );
            {
                JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
                jitTransientMetrics.addedLiquidity = jitLiquidityDelta.toInt128().toUint128();
                jitTransientMetrics.jitPositionInfo = poolKey.initialize(
                    beforeSwapTick,
                    expectedAfterSwapTick
                );

                assembly{
                    tstore(JIT_Transient_MetricsLocation, jitTransientMetrics)
                }
            }
        } 
        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, uint24(0x00));
    }



    // NOTE: For this Hook the bytes hookData is to implement further calls

    // before the transaction ends

    function _afterSwap(
        address,
        PoolKey calldata poolKey,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, int128)
    {
        bytes32 jitPositionKey = _jitPositionKey();
        
        jitOperator.removeJITLiquidity(
            jitPositionKey,
            hookData
        );

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
        
        PositionInfo jitPositionInfo = _jitPositionInfo();
        bytes32 lpPositionKey = sender.calculatePositionKey(
                liquidityParams.tickLower,
                liquidityParams.tickUpper,
                liquidityParams.salt            
            );
        uint128 jitLiquidity = _addedLiquidity();
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        {
            // =====================JIT=======================
            if (jitLiquidity > 0){
                jitTransientMetrics.positionKey = lpPositionKey;
                jitTransientMetrics.withheldFees = _withheldFees() + feeDelta;
                poolKey.currency0.take(
                    poolManager, 
                    address(this),
                    uint256(uint128(feeDelta.amount0())),
                    true
                );
                poolKey.currency1.take(
                    poolManager,
                    address(this),
                    uint256(uint128(feeDelta.amount1())),
                    true
                );

            }else {
                jitTransientMetrics.positionKey = bytes32(uint256(0x00));
            }

        }
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
        bytes32 jitPositionKey = _jitPositionKey();
        {
            //===================JIT========================
            if (jitPositionKey != bytes32(uint256(0x00))){
                BalanceDelta initialFeeDelta = _withheldFees();
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

}


