// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import "v4-core/libraries/Pool.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {BitMath} from "v4-core/libraries/BitMath.sol";

struct SwapSimulation {
    IPoolManager manager;
    PoolId poolId;
    Pool.SwapParams swapParams;
}

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
        //  * Layout:
        //  * 24 bits empty | 24 bits lpFee | 12 bits protocolFee 1->0 | 12 bits protocolFee 0->1 | 24 bits tick | 160 bits sqrtPriceX96

        Pool.SwapParams memory params = simulation.swapParams;
        bool zeroForOne = params.zeroForOne;

        uint256 protocolFee = zeroForOne
            ? _protocolFee.getZeroForOneFee()
            : _protocolFee.getOneForZeroFee();

        // the amount remaining to be swapped in/out of the input/output asset. initially set to the amountSpecified
        int256 amountSpecifiedRemaining = params.amountSpecified;
        // the amount swapped out/in of the output/input asset. initially set to 0
        int256 amountCalculated = 0;
        // initialize to the current sqrt(price)
        result.sqrtPriceX96 = _sqrtPriceX96;
        // initialize to the current tick
        result.tick = _tick;
        // initialize to the current liquidity
        result.liquidity = simulation.manager.getLiquidity(simulation.poolId);

        // if the beforeSwap hook returned a valid fee override, use that as the LP fee, otherwise load from storage
        // lpFee, swapFee, and protocolFee are all in pips
        {
            uint24 lpFee = params.lpFeeOverride.isOverride()
                ? params.lpFeeOverride.removeOverrideFlagAndValidate()
                : _lpFee;

            swapFee = protocolFee == 0
                ? lpFee
                : uint16(protocolFee).calculateSwapFee(lpFee);
        }

        // a swap fee totaling MAX_SWAP_FEE (100%) makes exact output swaps impossible since the input is entirely consumed by the fee
        if (swapFee >= SwapMath.MAX_SWAP_FEE) {
            // if exactOutput
            if (params.amountSpecified > 0) {
                Pool.InvalidFeeForExactOut.selector.revertWith();
            }
        }

        // swapFee is the pool's fee in pips (LP fee + protocol fee)
        // when the amount swapped is 0, there is no protocolFee applied and the fee amount paid to the protocol is set to 0
        if (params.amountSpecified == 0)
            return (BalanceDeltaLibrary.ZERO_DELTA, 0, swapFee, result);

        if (zeroForOne) {
            if (params.sqrtPriceLimitX96 >= _sqrtPriceX96) {
                Pool.PriceLimitAlreadyExceeded.selector.revertWith(
                    _sqrtPriceX96,
                    params.sqrtPriceLimitX96
                );
            }
            // Swaps can never occur at MIN_TICK, only at MIN_TICK + 1, except at initialization of a pool
            // Under certain circumstances outlined below, the tick will preemptively reach MIN_TICK without swapping there
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

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
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

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext <= TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            }
            if (step.tickNext >= TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtPriceAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
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

            // if exactOutput
            if (params.amountSpecified > 0) {
                unchecked {
                    amountSpecifiedRemaining -= step.amountOut.toInt256();
                }
                amountCalculated -= (step.amountIn + step.feeAmount).toInt256();
            } else {
                // safe because we test that amountSpecified > amountIn + feeAmount in SwapMath
                unchecked {
                    amountSpecifiedRemaining += (step.amountIn + step.feeAmount)
                        .toInt256();
                }
                amountCalculated += step.amountOut.toInt256();
            }

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
            if (protocolFee > 0) {
                unchecked {
                    // step.amountIn does not include the swap fee, as it's already been taken from it,
                    // so add it back to get the total amountIn and use that to calculate the amount of fees owed to the protocol
                    // cannot overflow due to limits on the size of protocolFee and params.amountSpecified
                    // this rounds down to favor LPs over the protocol
                    uint256 delta = (swapFee == protocolFee)
                        ? step.feeAmount // lp fee is 0, so the entire fee is owed to the protocol instead
                        : ((step.amountIn + step.feeAmount) * protocolFee) /
                            ProtocolFeeLibrary.PIPS_DENOMINATOR;
                    // subtract it from the total fee and add it to the protocol fee
                    step.feeAmount -= delta;
                    amountToProtocol += delta;
                }
            }

            // update global fee tracker
            if (result.liquidity > 0) {
                unchecked {
                    // FullMath.mulDiv isn't needed as the numerator can't overflow uint256 since tokens have a max supply of type(uint128).max
                    step.feeGrowthGlobalX128 += UnsafeMath.simpleMulDiv(
                        step.feeAmount,
                        FixedPoint128.Q128,
                        result.liquidity
                    );
                }
            }

            // Shift tick if we reached the next price, and preemptively decrement for zeroForOne swaps to tickNext - 1.
            // If the swap doesn't continue (if amountRemaining == 0 or sqrtPriceLimit is met), slot0.tick will be 1 less
            // than getTickAtSqrtPrice(slot0.sqrtPrice). This doesn't affect swaps, but donation calls should verify both
            // price and tick to reward the correct LPs.
            if (result.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
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
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
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
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                result.tick = TickMath.getTickAtSqrtPrice(result.sqrtPriceX96);
            }
        }

        // Slot0 resSlot0 = slot0Start.setTick(result.tick).setSqrtPriceX96(
        //     result.sqrtPriceX96
        // );

        // update liquidity if it changed
        // if (simulation.manager.getLiquidity() != result.liquidity)
        //     self.liquidity = result.liquidity;

        // // update fee growth global
        // if (!zeroForOne) {
        //     self.feeGrowthGlobal1X128 = step.feeGrowthGlobalX128;
        // } else {
        //     self.feeGrowthGlobal0X128 = step.feeGrowthGlobalX128;
        // }

        unchecked {
            // "if currency1 is specified"
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
                // all the 1s at or to the right of the current bitPos
                uint256 mask = type(uint256).max >>
                    (uint256(type(uint8).max) - bitPos);
                uint256 masked = tickBitMap & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (compressed -
                        int24(
                            uint24(bitPos - BitMath.mostSignificantBit(masked))
                        )) * __tickSpacing
                    : (compressed - int24(uint24(bitPos))) * __tickSpacing;
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (int16 wordPos, uint8 bitPos) = (++compressed).position();
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = tickBitMap & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
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

    // TODO: We need to implement the swapSimultioon as it where to be filled with JIT
    // liquidity, this is
    // struct ModifyLiquidityParams {
    //     // the address that owns the position
    //     address owner;
    //     // the lower and upper tick of the position
    //     int24 tickLower;
    //     int24 tickUpper;
    //     // any change in liquidity
    //     int128 liquidityDelta;
    //     // the spacing between ticks
    //     int24 tickSpacing;
    //     // used to distinguish positions of the same owner, at the same tick range
    //     bytes32 salt;
    // }

    // struct SwapResult {
    //     // the current sqrt(price)
    //     uint160 sqrtPriceX96;
    //     // the tick associated with the current price
    //     int24 tick;
    //     // the current liquidity in range
    //     uint128 liquidity;
    // }

    // NOTE Here we use the int128 liquidityDelta from ModifyLiquidityParams instead of the
    // the int128 liquidity from the SwapResult. This is
    // function simulateSwapJITLiquidity(
    //     SwapSimulation memory simulation
    // )
    //     internal
    //     view
    //     returns (
    //         BalanceDelta swapDelta,
    //         uint256 amountToProtocol,
    //         uint24 swapFee,
    //         Pool.SwapResult memory result
    //     ){

    //     }
}
