// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityOperator.sol";

abstract contract LiquidityOperator is ILiquidityOperator {
    mapping(bytes32 positionKey => TimeCommitment)
        private liquidityTimeCommitments;
}
