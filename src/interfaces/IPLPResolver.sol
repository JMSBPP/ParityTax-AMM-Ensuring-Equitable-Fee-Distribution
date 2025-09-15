// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IPLPResolver
 * @author ParityTax Team
 * @notice Interface for Passive Liquidity Provider (PLP) resolvers in the ParityTax system
 * @dev Defines the core functions for managing PLP liquidity commitments and removals.
 * PLP resolvers handle long-term liquidity commitments with specific block number
 * commitments, enabling the equitable fee distribution system's passive liquidity
 * management and reward distribution mechanisms.
 */

import {PoolId, PoolKey, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IPLPResolver is IAccessControl{
    // ================================ CUSTOM ERRORS ================================
    
    /// @notice Error thrown when commitment block number is not greater than current block
    error InvalidCommitment___MustBeGreaterThanCurrentBlock();
    
    // ================================ EXTERNAL FUNCTIONS ================================
    
    /**
     * @notice Commits liquidity for a Passive Liquidity Provider (PLP)
     * @dev Creates a new PLP position with specified liquidity parameters and commitment duration.
     * The committer agrees to maintain liquidity until the specified block number for enhanced rewards.
     * @param poolKey The pool configuration for the liquidity position
     * @param liquidityParams The liquidity parameters including tick range and amount
     * @param committer The address committing the liquidity (will own the position NFT)
     * @param blockNumber The block number until which liquidity must be committed
     * @return uint256 The token ID of the created position NFT
     */
    function commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        address committer,
        uint48 blockNumber
    ) external returns(uint256);

    /**
     * @notice Removes liquidity from a PLP position
     * @dev Removes the specified amount of liquidity from a PLP position, potentially
     * subject to commitment penalties if removed before the committed block number.
     * @param poolId The pool identifier for the position
     * @param tokenId The token ID of the position to modify
     * @param liquidityDelta The amount of liquidity to remove (negative value)
     */
    function removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) external;
}