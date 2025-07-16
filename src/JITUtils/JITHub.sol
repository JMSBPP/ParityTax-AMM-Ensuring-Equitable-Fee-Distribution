// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "openzeppelin/utils/structs/DoubleEndedQueue.sol";
import "openzeppelin/utils/structs/EnumerableMap.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {ImmutableState} from "v4-periphery/src/base/ImmutableState.sol";

import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {IJITHub, JITLiquidityResult} from "./interfaces/IJITHub.sol";

import {ToxicityLevel, ToxicityLevelLibrary} from "./types/ToxicityLevel.sol";
import {SwapData, SwapDataLibrary} from "./types/SwapData.sol";
import {JITLiquidityDistributionOnSwap, JITLiquidityDistributionOnSwapLibrary} from "./types/JITLiquidityDistributionOnSwap.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {Pool} from "v4-core/libraries/Pool.sol";
import {ParseBytes} from "v4-core/libraries/ParseBytes.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {SafeCast as SafeCastV4} from "v4-core/libraries/SafeCast.sol";
import {SwapSimulation, SwapSimulationLibrary} from "./types/SwapSimulation.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";

/**
 * @title JITHub
 * @author j-money-11
 * @notice This contract is responsible for calculating the optimal parameters for JIT liquidity provision.
 * @dev It simulates swaps to determine profitability and the required liquidity parameters.
 */
contract JITHub is IJITHub, ImmutableState {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using ParseBytes for bytes;
    using LPFeeLibrary for uint24;
    using SafeCastV4 for *;
    using SwapSimulationLibrary for SwapSimulation;
    using BalanceDeltaLibrary for BalanceDelta;
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;

    /// @dev Mapping to store swap data classified by toxicity level.
    mapping(PoolId poolId => mapping(ToxicityLevel toxicityLevel => SwapData))
        private _tradingVolumeClassifiedData;

    /// @dev Mapping to store general swap data.
    mapping(PoolId poolId => SwapData) private _tradingVolumeData;

    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    /**
     * @inheritdoc IJITHub
     */
    function calculateJITLiquidityParamsForSwap(
        address routerSender,
        PoolKey memory poolKey,
        SwapParams memory swapParams
    ) external view override returns (JITLiquidityResult memory jitLiquidityResult) {
        PoolId poolId = poolKey.toId();
        (
            uint160 priceBeforeSwapX96,
            ,
            ,
            
        ) = poolManager.getSlot0(poolId);

        Pool.SwapParams memory simulationSwapParams = Pool.SwapParams({
            amountSpecified: swapParams.amountSpecified,
            tickSpacing: poolKey.tickSpacing,
            zeroForOne: swapParams.zeroForOne,
            sqrtPriceLimitX96: swapParams.sqrtPriceLimitX96,
            lpFeeOverride: poolKey.fee
        });
        SwapSimulation memory simulation = SwapSimulation({
            manager: poolManager,
            poolId: poolId,
            swapParams: simulationSwapParams
        });

        (
            BalanceDelta memory swapDelta,
            ,
            uint24 swapFee,
            Pool.SwapResult memory result
        ) = simulation.simulateSwapPLPLiquidity();

        uint160 priceAfterSwapX96 = result.sqrtPriceX96;
        uint256 priceImpact = priceAfterSwapX96.absDiff(priceBeforeSwapX96);

        unchecked {
            jitLiquidityResult = JITLiquidityResult({
                isProfitable: uint256(swapFee) * 2 >= priceImpact,
                swapDelta: swapDelta,
                jitLiquidityParams: ModifyLiquidityParams({
                    tickLower: result.tick - poolKey.tickSpacing,
                    tickUpper: result.tick + poolKey.tickSpacing,
                    liquidityDelta: swapParams.zeroForOne
                        ? priceBeforeSwapX96
                            .getLiquidityForAmount0(
                                priceAfterSwapX96,
                                uint256(
                                    swapDelta.amount0() < 0
                                        ? -int256(swapDelta.amount0())
                                        : int256(swapDelta.amount0())
                                )
                            )
                            .toInt256()
                        : priceAfterSwapX96
                            .getLiquidityForAmount1(
                                priceBeforeSwapX96,
                                uint256(
                                    swapDelta.amount1() < 0
                                        ? -int256(swapDelta.amount1())
                                        : int256(swapDelta.amount1())
                                )
                            )
                            .toInt256(),
                    salt: keccak256(
                        abi.encodePacked(
                            routerSender,
                            priceBeforeSwapX96,
                            priceAfterSwapX96
                        )
                    )
                }),
                priceImpact: priceImpact,
                swapFee: swapFee
            });
        }
    }

    /**
     * @notice Pushes new swap data to the trading volume history.
     * @param poolId The ID of the pool.
     * @param enteredSwapParams The parameters of the swap to record.
     */
    function pushSwapData(
        PoolId poolId,
        SwapParams memory enteredSwapParams
    ) private {
        _tradingVolumeData[poolId].poolSwaps.push(enteredSwapParams);
    }
}