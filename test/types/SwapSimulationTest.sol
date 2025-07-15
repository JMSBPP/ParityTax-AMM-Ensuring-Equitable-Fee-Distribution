// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SwapSimulation, SwapSimulationLibrary} from "../../src/JITUtils/types/SwapSimulation.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {Pool} from "v4-core/libraries/Pool.sol";

contract SwapSimulationLibraryHelper {
    using SwapSimulationLibrary for SwapSimulation;

    function simulateSwapPLPLiquidity(
        SwapSimulation memory simulation
    )
        external
        view
        returns (
            BalanceDelta swapDelta,
            uint256 amountToProtocol,
            uint24 swapFee,
            Pool.SwapResult memory result
        )
    {
        return simulation.simulateSwapPLPLiquidity();
    }

    function SwapSimulationCrossTick(
        SwapSimulation memory simulation,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) external view returns (int128 liquidityNet) {
        return
            simulation.SwapSimulationCrossTick(
                tick,
                feeGrowthGlobal0X128,
                feeGrowthGlobal1X128
            );
    }

    function SwapSimulationNextInitializedTickWithinOneWord(
        SwapSimulation memory simulation,
        int16 tickWordPos,
        int24 __tick,
        int24 __tickSpacing,
        bool zeroForOne
    ) external view returns (int24 next, bool initialized) {
        return
            simulation.SwapSimulationNextInitializedTickWithinOneWord(
                tickWordPos,
                __tick,
                __tickSpacing,
                zeroForOne
            );
    }
}
