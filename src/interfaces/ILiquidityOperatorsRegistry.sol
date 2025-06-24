// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../hooks/interfaces/ILiquidityOperator.sol";
import "../types/LPTimeCommitment.sol";

error InvalidLiquidityProvider____AddressIsZero();
interface ILiquidityOperatorsRegistry {
    //NOTE: This function ius callled only by the router

    function setLPTimeCommitment(
        address liquidityProvider,
        LPTimeCommitment memory lpTypeTimeCommitment
    ) external;

    function getLPTimeCommitment(
        address liquidityProvider
    ) external view returns (LPTimeCommitment memory);
}
