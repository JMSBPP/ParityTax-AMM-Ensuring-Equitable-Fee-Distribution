// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../hooks/interfaces/ILiquidityOperator.sol";
import "../types/LPTimeCommitment.sol";

interface ILiquidityOperatorsRegistry {
    function getLPType(
        address liquidityProvider
    ) external view returns (LPType lpType);

    function getLiquidityOperator(
        address liquidityProvider
    ) external view returns (ILiquidityOperator liquidityOperator);

    function setLiquidityOperator(
        address liquidityProvider,
        ILiquidityOperator liquidityOperator
    ) external;

    function setLPTimeCommitment(
        address liquidityProvider,
        LPTimeCommitment memory lpTimeCommitment
    ) external;

    function getLPTimeCommitment(
        address liquidityProvider
    ) external view returns (LPTimeCommitment memory lpTimeCommitment);
}
