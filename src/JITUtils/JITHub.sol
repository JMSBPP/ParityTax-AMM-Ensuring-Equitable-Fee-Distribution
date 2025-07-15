// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//TODO: Candidate data structures for indexing swap data
// based on toxicity
// ============ DATA STRUCTRUES  =====================
import "openzeppelin/utils/structs/DoubleEndedQueue.sol";
import "openzeppelin/utils/structs/EnumerableMap.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {ImmutableState} from "v4-periphery/src/base/ImmutableState.sol";

// =============UNISWAP OWN TYPES============================
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
// ===================INTERFACES ================
import {IJITHub, JITLiquidityResult} from "./interfaces/IJITHub.sol";

// ================CUSTOM TYPES IMPORTS =======
import {ToxicityLevel, ToxicityLevelLibrary} from "./types/ToxicityLevel.sol";
import {SwapData, SwapDataLibrary} from "./types/SwapData.sol";
import {JITLiquidityDistributionOnSwap, JITLiquidityDistributionOnSwapLibrary} from "./types/JITLiquidityDistributionOnSwap.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
//NOTE: This contract is owned or administeed by the TaxController
import {Pool} from "v4-core/libraries/Pool.sol";
import {ParseBytes} from "v4-core/libraries/ParseBytes.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {SafeCast as SafeCastV4} from "v4-core/libraries/SafeCast.sol";
import {SwapSimulation, SwapSimulationLibrary} from "./types/SwapSimulation.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
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
    mapping(PoolId poolId => mapping(ToxicityLevel toxicityLevel => SwapData))
        private _tradingVolumeClassifiedData;

    mapping(PoolId poolId => SwapData) private _tradingVolumeData;
    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    //NOTE: This function is called the ParityTaxHook
    // This is a feature to intgrate with Bunni to be considered on future
    // iterations

    // TODO: From now as shown on ./spec/Ref2.sol The JIT conditions for profitability is
    // not dependant on the level of liquidity provided on a certain tick-range for a given swap
    // bt depends on the price impact and on the trading fee
    // IDEA: This means that dynamic fee can be designed to incentivize JIT's on certain assets
    function calculateJITLiquidityParamsForSwap(
        address routerSender, // This needs to be passed
        // from the hook to the JITHub
        PoolKey memory poolKey,
        SwapParams memory swapParams
    ) external view returns (JITLiquidityResult memory jitLiquidityResult) {
        // TODO: We need to get the price impact this is the
        // distance between the price before excecution and the price after excecution
        // 1. Retrieve the current price, and state variables of interest
        PoolId poolId = poolKey.toId();
        (
            uint160 priceBeforeSwapX96,
            int24 tickPriceBeforeSwap,
            uint24 protocolFee,
            uint24 swapFeeBeforeSwap
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
        // TODO: This is to be changed for simulateSwapJITLiquidity
        (
            BalanceDelta swapDelta,
            uint256 amountToProtocol,
            uint24 swapFee,
            Pool.SwapResult memory result
        ) = simulation.simulateSwapPLPLiquidity();
        // // Tracks the state of a pool throughout a swap, and returns these values at the end of the swap
        // struct SwapResult
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

    // NOTE This function needs to have access control

    function pushSwapData(
        PoolId poolId,
        SwapParams memory enteredSwapParams
    ) private {
        _tradingVolumeData[poolId].poolSwaps.push(enteredSwapParams);
    }
}
