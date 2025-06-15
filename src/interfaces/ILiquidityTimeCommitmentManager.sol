// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../types/LiquidityTimeCommitmentData.sol";

interface ILiquidityTimeCommitmentManager {
    function getPositionTimeCommitment(
        bytes32 positionKey
    ) external view returns (TimeCommitment memory timeCommitment);

    function directLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        bool isJIT,
        bytes32 liquidityPositionKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external;
}
