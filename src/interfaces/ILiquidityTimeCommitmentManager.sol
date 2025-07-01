// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../types/TimeCommitment.sol";
import "v4-core/types/PoolKey.sol";
import "v4-core/libraries/StateLibrary.sol";
import "v4-periphery/src/base/ImmutableState.sol";

interface ILiquidityTimeCommitmentManager {
    event PositionTimeCommitmentUpdated(
        PoolId indexed poolId,
        bytes32 indexed positionKey,
        uint48 indexed timeCommitmentValue,
        uint128 liquidity
    );
    function updatePositionTimeCommitment(
        bytes32 positionKey,
        PoolKey memory poolKey,
        TimeCommitment enteredTimeCommitment
    ) external;

    function getTimeCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns (TimeCommitment);
}
