// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityOperatorsRegistry.sol";
contract LiquidityOperatorsRegistry is ILiquidityOperatorsRegistry {
    using LPTimeCommitmentLibrary for LPTimeCommitment;

    //TODO: We need to account for invariants that need to hoold when storing ddta on this
    // mappings ...
    mapping(address liquidityProvider => ILiquidityOperator)
        private liquidityOperators;

    mapping(address liquidityProvider => LPTimeCommitment)
        private lpTimeCommitments;

    //NOTE: The default valo for not assigned lp's should be
    // LPType.NONE

    function getLPType(
        address liquidityProvider
    ) external view returns (LPType lpType) {
        lpType = lpTimeCommitments[liquidityProvider].lpType;
    }
    function getLiquidityOperator(
        address liquidityProvider
    ) external view returns (ILiquidityOperator liquidityOperator) {
        liquidityOperator = liquidityOperators[liquidityProvider];
    }
    //TODO: This function needs to do the following:
    function setLiquidityOperator(
        address liquidityProvider,
        ILiquidityOperator liquidityOperator
    ) external {
        // 1. It is conly callabale when there is a valid lpTimeCommitment
        // already  set on the lpTimeCommitments
        //2. Based on the LPtype it needs to assign
        // the correct liquidityOperator
        // if (lpTimeCommitments[liquidityProvider].lpType == LPType.JIT) {
        //     _validateJITLiquidityOperator(liquidityOperator);
        //     liquidityOperators[liquidityProvider] = liquidityOperator;
        // } else if (lpTimeCommitments[liquidityProvider].lpType == LPType.PLP) {
        //     _validatePLPLiquidityOperator(liquidityOperator);
        //     liquidityOperators[liquidityProvider] = liquidityOperator;
        // }
    }

    function setLPTimeCommitment(
        address liquidityProvider,
        LPTimeCommitment memory lpTimeCommitment
    ) external {
        lpTimeCommitments[liquidityProvider] = lpTimeCommitment;
    }

    function getLPTimeCommitment(
        address liquidityProvider
    ) external view returns (LPTimeCommitment memory lpTimeCommitment) {
        lpTimeCommitment = lpTimeCommitments[liquidityProvider];
    }
}
