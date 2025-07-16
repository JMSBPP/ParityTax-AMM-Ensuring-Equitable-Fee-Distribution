// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../types/TimeCommitment.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/StateLibrary.sol";
import "v4-periphery/src/base/ImmutableState.sol";

/**
 * @title ILiquidityTimeCommitmentManager
 * @author j-money-11
 * @notice Interface for the LiquidityTimeCommitmentManager contract.
 * @dev This interface defines the external functions for managing time commitments of liquidity positions.
 */
interface ILiquidityTimeCommitmentManager {
    /**
     * @notice Emitted when the time commitment of a position is updated.
     * @param poolId The ID of the pool.
     * @param positionKey The key of the position.
     * @param timeCommitmentValue The new time commitment value.
     * @param liquidity The liquidity of the position.
     */
    event PositionTimeCommitmentUpdated(
        PoolId indexed poolId,
        bytes32 indexed positionKey,
        uint48 indexed timeCommitmentValue,
        uint128 liquidity
    );

    /**
     * @notice Updates the time commitment of a specific liquidity position.
     * @param positionKey The key of the position to update.
     * @param poolKey The key of the pool.
     * @param enteredTimeCommitment The new time commitment to set.
     */
    function updatePositionTimeCommitment(
        bytes32 positionKey,
        PoolKey memory poolKey,
        TimeCommitment enteredTimeCommitment
    ) external;

    /**
     * @notice Retrieves the time commitment of a specific liquidity position.
     * @param poolId The ID of the pool.
     * @param positionKey The key of the position.
     * @return TimeCommitment The time commitment of the position.
     */
    function getTimeCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns (TimeCommitment);
}