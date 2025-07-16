// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import "v4-core/libraries/Pool.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {BitMath} from "v4-core/libraries/BitMath.sol";

/// @title SwapSimulation
/// @author j-money-11
/// @notice A struct to hold the parameters for simulating a swap.
struct SwapSimulation {
    IPoolManager manager;
    PoolId poolId;
    Pool.SwapParams swapParams;
}

/// @title SwapSimulationLibrary
/// @author j-money-11
/// @notice A library for simulating swaps in a Uniswap V4 pool.
/// @dev This library is crucial for the JITHub to predict the outcome of a swap
/// and determine if providing JIT liquidity would be profitable.
library SwapSimulationLibrary {
    using SafeCast for *;
    using TickBitmap for *;
    using StateLibrary for IPoolManager;
    using Pool for Pool.State;
    using BalanceDeltaLibrary for BalanceDelta;
    using ProtocolFeeLibrary for *;
    using LPFeeLibrary for uint24;
    using CustomRevert for bytes4;
    using SwapSimulationLibrary for SwapSimulation;

    /// @notice Simulates a swap with the current passive liquidity in the pool.
    /// @param simulation The SwapSimulation struct containing the simulation parameters.
    /// @return swapDelta The change in balances resulting from the swap.
    /// @return amountToProtocol The amount of fees paid to the protocol.
    /// @return swapFee The swap fee.
    /// @return result The result of the swap simulation.
    function simulateSwapPLPLiquidity(
        SwapSimulation memory simulation
    )
        internal
        view
        returns (
            BalanceDelta swapDelta,
            uint256 amountToProtocol,
            uint24 swapFee,
            Pool.SwapResult memory result
        )
    {
        (
            uint160 _sqrtPriceX96,
            int24 _tick,
            uint24 _protocolFee,
            uint24 _lpFee
        ) = simulation.manager.getSlot0(simulation.poolId);

        Pool.SwapParams memory params = simulation.swapParams;
        bool zeroForOne = params.zeroForOne;

        uint256 protocolFee = zeroForOne
            ? _protocolFee.getZeroForOneFee()
            : _protocolFee.getOneForZeroFee();

        int256 amountSpecifiedRemaining = params.amountSpecified;
        int256 amountCalculated = 0;
        result.sqrtPriceX96 = _sqrtPriceX96;
        result.tick = _tick;
        result.liquidity = simulation.manager.getLiquidity(simulation.poolId);

        {
            uint24 lpFee = params.lpFeeOverride.isOverride()
                ? params.lpFeeOverride.removeOverrideFlagAndValidate()
                : _lpFee;

            swapFee = protocolFee == 0
                ? lpFee
                : uint16(protocolFee).calculateSwapFee(lpFee);
        }

        if (swapFee >= SwapMath.MAX_SWAP_FEE) {
            if (params.amountSpecified > 0) {
                Pool.InvalidFeeForExactOut.selector.revertWith();
            }
        }

        if (params.amountSpecified == 0)
            return (BalanceDeltaLibrary.ZERO_DELTA, 0, swapFee, result);

        if (zeroForOne) {
            if (params.sqrtPriceLimitX96 >= _sqrtPriceX96) {
                Pool.PriceLimitAlreadyExceeded.selector.revertWith(
                    _sqrtPriceX96,
                    params.sqrtPriceLimitX96
                );
            }
            if (params.sqrtPriceLimitX96 <= TickMath.MIN_SQRT_PRICE) {
                Pool.PriceLimitOutOfBounds.selector.revertWith(
                    params.sqrtPriceLimitX96
                );
            }
        } else {
            if (params.sqrtPriceLimitX96 <= _sqrtPriceX96) {
                Pool.PriceLimitAlreadyExceeded.selector.revertWith(
                    _sqrtPriceX96,
                    params.sqrtPriceLimitX96
                );
            }
            if (params.sqrtPriceLimitX96 >= TickMath.MAX_SQRT_PRICE) {
                Pool.PriceLimitOutOfBounds.selector.revertWith(
                    params.sqrtPriceLimitX96
                );
            }
        }
        (uint256 feeGrowthGlobal0, uint256 feeGrowthGlobal1) = simulation
            .manager
            .getFeeGrowthGlobals(simulation.poolId);
        Pool.StepComputations memory step;
        step.feeGrowthGlobalX128 = zeroForOne
            ? feeGrowthGlobal0
            : feeGrowthGlobal1;

        while (
            !(amountSpecifiedRemaining == 0 ||
                result.sqrtPriceX96 == params.sqrtPriceLimitX96)
        ) {
            step.sqrtPriceStartX96 = result.sqrtPriceX96;
            (int16 wordPos, ) = _tick.position();

            (step.tickNext, step.initialized) = simulation
                .SwapSimulationNextInitializedTickWithinOneWord(
                    wordPos,
                    result.tick,
                    params.tickSpacing,
                    zeroForOne
                );

            if (step.tickNext <= TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            }
            if (step.tickNext >= TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            step.sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(step.tickNext);

            (
                result.sqrtPriceX96,
                step.amountIn,
                step.amountOut,
                step.feeAmount
            ) = SwapMath.computeSwapStep(
                result.sqrtPriceX96,
                SwapMath.getSqrtPriceTarget(
                    zeroForOne,
                    step.sqrtPriceNextX96,
                    params.sqrtPriceLimitX96
                ),
                result.liquidity,
                amountSpecifiedRemaining,
                swapFee
            );

            if (params.amountSpecified > 0) {
                unchecked {
                    amountSpecifiedRemaining -= step.amountOut.toInt256();
                }
                amountCalculated -= (step.amountIn + step.feeAmount).toInt256();
            } else {
                unchecked {
                    amountSpecifiedRemaining += (step.amountIn + step.feeAmount)
                        .toInt256();
                }
                amountCalculated += step.amountOut.toInt256();
            }

            if (protocolFee > 0) {
                unchecked {
                    uint256 delta = (swapFee == protocolFee)
                        ? step.feeAmount
                        : ((step.amountIn + step.feeAmount) * protocolFee) /
                            ProtocolFeeLibrary.PIPS_DENOMINATOR;
                    step.feeAmount -= delta;
                    amountToProtocol += delta;
                }
            }

            if (result.liquidity > 0) {
                unchecked {
                    step.feeGrowthGlobalX128 += UnsafeMath.simpleMulDiv(
                        step.feeAmount,
                        FixedPoint128.Q128,
                        result.liquidity
                    );
                }
            }

            if (result.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    (
                        uint256 feeGrowthGlobal0X128,
                        uint256 feeGrowthGlobal1X128
                    ) = zeroForOne
                            ? (step.feeGrowthGlobalX128, feeGrowthGlobal1)
                            : (feeGrowthGlobal0, step.feeGrowthGlobalX128);
                    int128 liquidityNet = simulation.SwapSimulationCrossTick(
                        step.tickNext,
                        feeGrowthGlobal0X128,
                        feeGrowthGlobal1X128
                    );
                    unchecked {
                        if (zeroForOne) liquidityNet = -liquidityNet;
                    }

                    result.liquidity = LiquidityMath.addDelta(
                        result.liquidity,
                        liquidityNet
                    );
                }

                unchecked {
                    result.tick = zeroForOne
                        ? step.tickNext - 1
                        : step.tickNext;
                }
            } else if (result.sqrtPriceX96 != step.sqrtPriceStartX96) {
                result.tick = TickMath.getTickAtSqrtPrice(result.sqrtPriceX96);
            }
        }

        unchecked {
            if (zeroForOne != (params.amountSpecified < 0)) {
                swapDelta = toBalanceDelta(
                    amountCalculated.toInt128(),
                    (params.amountSpecified - amountSpecifiedRemaining)
                        .toInt128()
                );
            } else {
                swapDelta = toBalanceDelta(
                    (params.amountSpecified - amountSpecifiedRemaining)
                        .toInt128(),
                    amountCalculated.toInt128()
                );
            }
        }
    }

    function SwapSimulationCrossTick(
        SwapSimulation memory simulation,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (int128 liquidityNet) {
        unchecked {
            (
                uint128 TickInfo_liquidityGross,
                int128 TickInfo_liquidityNet,
                uint256 TickInfo_feeGrowthOutside0X128,
                uint256 TickInfo_feeGrowthOutside1X128
            ) = simulation.manager.getTickInfo(simulation.poolId, tick);
            TickInfo_feeGrowthOutside0X128 =
                feeGrowthGlobal0X128 -
                TickInfo_feeGrowthOutside0X128;
            TickInfo_feeGrowthOutside1X128 =
                feeGrowthGlobal1X128 -
                TickInfo_feeGrowthOutside1X128;
            liquidityNet = TickInfo_liquidityNet;
        }
    }

    function SwapSimulationNextInitializedTickWithinOneWord(
        SwapSimulation memory simulation,
        int16 tickWordPos,
        int24 __tick,
        int24 __tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        uint256 tickBitMap = simulation.manager.getTickBitmap(
            simulation.poolId,
            tickWordPos
        );
        unchecked {
            int24 compressed = __tick.compress(__tickSpacing);

            if (lte) {
                (int16 wordPos, uint8 bitPos) = compressed.position();
                uint256 mask = type(uint256).max >>
                    (uint256(type(uint8).max) - bitPos);
                uint256 masked = tickBitMap & mask;

                initialized = masked != 0;
                next = initialized
                    ? (compressed -
                        int24(
                            uint24(bitPos - BitMath.mostSignificantBit(masked))
                        )) * __tickSpacing
                    : (compressed - int24(uint24(bitPos))) * __tickSpacing;
            } else {
                (int16 wordPos, uint8 bitPos) = (++compressed).position();
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = tickBitMap & mask;

                initialized = masked != 0;
                next = initialized
                    ? (compressed +
                        int24(
                            uint24(BitMath.leastSignificantBit(masked) - bitPos)
                        )) * __tickSpacing
                    : (compressed + int24(uint24(type(uint8).max - bitPos))) *
                        __tickSpacing;
            }
        }
    }
}