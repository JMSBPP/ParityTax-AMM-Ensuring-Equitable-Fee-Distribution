// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../types/LiquidityTimeCommitmentData.sol";
interface ILiquidityOperator {
    //NOTE: This funciton is only callable by the liquidityTimeCommitmen
    // Manager
    function setPositionTimeCommitment(
        bytes32 liquidityTimeCommitment,
        TimeCommitment memory timeCommitment
    ) external;
    function getPositionTimeCommitment(
        bytes32 liquidityTimeCommitment
    ) external view returns (TimeCommitment memory timeCommitment);
}
