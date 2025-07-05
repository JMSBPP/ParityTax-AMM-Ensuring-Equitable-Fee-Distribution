// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityTimeCommitmentManager.sol";

contract LiquidityTimeCommitmentManager is
    ImmutableState,
    ILiquidityTimeCommitmentManager
{
    using StateLibrary for IPoolManager;

    mapping(PoolId poolId => mapping(bytes32 positionKey => TimeCommitment timeCommitment))
        private positionTimeCommitment;

    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    function updatePositionTimeCommitment(
        bytes32 positionKey,
        PoolKey memory poolKey,
        TimeCommitment enteredTimeCommitment
    ) external {
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

    function getTimeCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns (TimeCommitment) {
        return positionTimeCommitment[poolId][positionKey];
    }
}
