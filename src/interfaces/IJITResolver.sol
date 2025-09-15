//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IJITResolver
 * @author ParityTax Team
 * @notice Interface for Just-In-Time (JIT) liquidity resolvers in the ParityTax system
 * @dev Defines the core functions for managing JIT liquidity provision and removal.
 * JIT resolvers handle short-term liquidity provision that is added just before a swap
 * and removed immediately after, enabling efficient liquidity utilization and fee
 * collection in the equitable fee distribution system.
 */

import {PositionConfig} from "@uniswap/v4-periphery/test/shared/PositionConfig.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import "../types/Shared.sol";

interface IJITResolver{
    // ================================ EXTERNAL FUNCTIONS ================================
    
    /**
     * @notice Adds JIT liquidity for a swap operation
     * @dev Creates temporary liquidity position just before a swap to provide optimal
     * liquidity depth. The liquidity is added based on swap context and market conditions.
     * @param swapContext The swap context containing swap parameters and market data
     * @return uint256 The token ID of the created JIT position
     * @return uint256 The amount of liquidity added
     */
    function addLiquidity(SwapContext memory swapContext) external returns(uint256, uint256);

    /**
     * @notice Removes JIT liquidity after swap completion
     * @dev Removes the temporary liquidity position after the swap operation is complete,
     * collecting fees and returning the position to the JIT provider.
     * @param liquidityPosition The liquidity position to remove
     */
    function removeLiquidity(LiquidityPosition memory liquidityPosition) external;
}