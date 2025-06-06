// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "./interfaces/ILiquidityTimeCommitmentStateQuerier.sol";

contract LiquidityTimeCommitmentState {
    ILiquidityTimeCommitmentStateQuerier private querier;
    mapping(PoolId poolId => mapping(bytes32 positionKey => TimeCommitment timeCommitment))
        internal timeCommitments;

    mapping(PoolId poolId => bytes32[] positions) internal poolPositions;

    function setStateQuerier(
        ILiquidityTimeCommitmentStateQuerier querierImpl
    ) internal {
        querier = querierImpl;
    }
}
