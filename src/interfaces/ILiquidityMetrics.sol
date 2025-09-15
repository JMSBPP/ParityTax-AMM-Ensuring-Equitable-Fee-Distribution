// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    PoolKey,
    SwapParams
} from "@uniswap/v4-core/src/types/PoolOperation.sol";

/**
 * @title ILiquidityMetrics
 * @author ParityTax Team
 * @notice Interface for calculating liquidity metrics for PLP and JIT providers
 * @dev Provides functions to calculate available liquidity for swaps across different tick ranges
 * and liquidity provider types (PLP and JIT)
 */
interface ILiquidityMetrics{

    /**
     * @notice Gets the available PLP liquidity for a swap within a specific tick range
     * @dev External function that calculates PLP liquidity across the specified tick range
     * @param poolKey Pool configuration data including currencies and fee tier
     * @param _tickLower The lower tick boundary for the liquidity calculation
     * @param _tickUpper The upper tick boundary for the liquidity calculation
     * @return The amount of PLP liquidity available for swaps in the specified range
     */
    function getSwapPLPLiquidity(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper 
    ) external view returns(uint128);

    /**
     * @notice Gets the available JIT liquidity for a swap within a specific tick range
     * @dev External function that calculates JIT liquidity based on swap parameters and tick range
     * @param poolKey Pool configuration data including currencies and fee tier
     * @param swapParams Swap parameters including amount and direction
     * @param _tickLower The lower tick boundary for the liquidity calculation
     * @param _tickUpper The upper tick boundary for the liquidity calculation
     * @return The amount of JIT liquidity available for the specified swap
     */
    function getSwapJITLiquidity(
        PoolKey memory poolKey,
        SwapParams memory swapParams,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns(uint128);

}
