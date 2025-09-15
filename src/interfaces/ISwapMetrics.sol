// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {
    PoolKey,
    SwapParams,
    BalanceDelta
} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import "../types/Shared.sol";

/**
 * @title ISwapMetrics
 * @author ParityTax Team
 * @notice Interface for calculating swap metrics and price impact analysis
 * @dev Provides functions to compare swap outputs between hooked and unhooked pools,
 * simulate price impact, and analyze swap performance metrics
 */
interface ISwapMetrics{

    /**
     * @notice Compares swap outputs between different pool configurations
     * @dev External function that calculates the difference in swap outputs between pools
     * @param hookedKey The pool key with hooks enabled
     * @param swapParams The swap parameters for the comparison
     * @param comparedPoolKey The pool key to compare against
     * @return delta The balance delta representing the difference in swap outputs
     */
    function compareSwapOutput(
        PoolKey memory hookedKey,
        SwapParams memory swapParams,
        PoolKey memory comparedPoolKey
    ) external view returns(BalanceDelta delta);

    /**
     * @notice Simulates swap output on an unhooked pool
     * @dev External function that simulates a swap on a pool without hooks using V4Quoter
     * @param hookedKey The original pool key with hooks (used to create unhooked version)
     * @param swapParams The swap parameters for simulation
     * @return delta The balance delta representing the swap impact
     * @return swapOutput The simulated swap output with amount in and out
     */
    function simulateSwapOutputOnUnHookedPool(
        PoolKey memory hookedKey,
        SwapParams memory swapParams
    ) external returns(BalanceDelta delta, SwapOutput memory swapOutput);

    /**
     * @notice Simulates price impact of a swap
     * @dev External function that calculates the expected price and tick after a swap
     * @param poolKey The pool configuration data
     * @param initialSqrtPriceX96 The initial sqrt price before the swap
     * @param liquidity The available liquidity for the swap
     * @param swapParams The swap parameters
     * @param swapOutput The expected swap output amounts
     * @return The expected sqrt price after the swap
     * @return The expected tick after the swap
     */
    function simulatePriceImpact(
        PoolKey memory poolKey,
        uint160 initialSqrtPriceX96,
        uint128 liquidity,
        SwapParams memory swapParams,
        SwapOutput memory swapOutput
    ) external view returns(uint160,int24);

}

