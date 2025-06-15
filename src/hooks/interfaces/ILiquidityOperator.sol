// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../types/LiquidityTimeCommitmentData.sol";
import "../../types/PositionTimeCommitmentKey.sol";
import "../../types/LiquidityPositionAccounting.sol";
import "v4-core/libraries/Position.sol";
import "v4-core/types/Currency.sol";
interface ILiquidityOperator {
    //NOTE: This funciton is only callable by the liquidityTimeCommitmen
    // Manager
    function setPositionLiquidityTimeCommitmentData(
        bytes32 positionKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external;
    function getPositionLiquidityTimeCommitmentData(
        bytes32 positionKey
    )
        external
        view
        returns (
            LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
        );

    function getLiquidityPositionAccounting(
        bytes32 positionTimeCommitmentKey
    )
        external
        view
        returns (
            LiquidityPositionAccounting memory liquidityPositionAccounting
        );

    function getClaimableLiquidityOnCurrency(
        Currency currency
    ) external view returns (uint256 claimableLiquidityBalance);
}
