// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {ImmutableState} from "v4-core/base/ImmutableState.sol";
import "./interfaces/ILiquidityTimeCommitmentStateQuerier.sol";

contract LiquidityTimeCommitmentState is ImmutableState {
    ILiquidityTimeCommitmentStateQuerier private querier;
    mapping(PoolId poolId => mapping(bytes32 positionKey => TimeCommitment timeCommitment))
        internal timeCommitments;

    mapping(PoolId poolId => bytes32[] positions) internal poolPositions;

    constructor(IPoolManager _poolManager) ImmutableState(_poolManager) {}

    function setStateQuerier(
        ILiquidityTimeCommitmentStateQuerier querierImpl
    ) internal {
        querier = querierImpl;
    }
}
