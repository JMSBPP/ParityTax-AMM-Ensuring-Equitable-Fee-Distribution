// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityTimeCommitmentManager.sol";
import {console} from "forge-std/Test.sol";

/**
 * @title LiquidityTimeCommitmentManager
 * @author j-money-11
 * @notice This contract manages the time commitments of liquidity positions in Uniswap V4 pools.
 * @dev It tracks the `TimeCommitment` for each position, allowing the system to differentiate
 * between PLPs and JITs and enforce time-based rules.
 */
contract LiquidityTimeCommitmentManager is
    ImmutableState,
    ILiquidityTimeCommitmentManager
{
    using StateLibrary for IPoolManager;

    /// @dev Mapping from pool ID to position key to TimeCommitment.
    mapping(PoolId poolId => mapping(bytes32 positionKey => TimeCommitment timeCommitment))
        private positionTimeCommitment;

    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    /**
     * @inheritdoc ILiquidityTimeCommitmentManager
     */
    function updatePositionTimeCommitment(
        bytes32 positionKey,
        PoolKey memory poolKey,
        TimeCommitment enteredTimeCommitment
    ) external override {
        TimeCommitment existingTimeCommitment = positionTimeCommitment[
            poolKey.toId()
        ][positionKey];

        if (UNINITIALIZED(existingTimeCommitment)) {
            existingTimeCommitment = toTimeCommitment(UNINITIALIZED_FLAG);
        }

        positionTimeCommitment[poolKey.toId()][positionKey] = add(
            existingTimeCommitment,
            enteredTimeCommitment
        );

        (uint128 liquidity, , ) = poolManager.getPositionInfo(
            poolKey.toId(),
            positionKey
        );

        emit PositionTimeCommitmentUpdated(
            poolKey.toId(),
            positionKey,
            timeCommitmentValue(
                positionTimeCommitment[poolKey.toId()][positionKey]
            ),
            liquidity
        );
    }

    /**
     * @inheritdoc ILiquidityTimeCommitmentManager
     */
    function getTimeCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view override returns (TimeCommitment) {
        return positionTimeCommitment[poolId][positionKey];
    }
}