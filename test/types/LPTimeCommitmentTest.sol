// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/types/LPTimeCommitment.sol";

contract LPTimeCommitmentTest {
    using LPTimeCommitmentLibrary for *;

    function validateAndSetLPTypeTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) external returns (LPTimeCommitment memory lpTypeTimeCommitment) {
        lpTypeTimeCommitment = enteredTimeCommitment
            .validateAndSetLPTypeTimeCommitment();
    }

    function setJITLpTimeCommitment(
        uint256 blockToCommitLiquidity,
        ILiquidityOperator liquidityOperator
    ) external returns (LPTimeCommitment memory) {
        return
            LPTimeCommitmentLibrary.setJITLpTimeCommitment(
                blockToCommitLiquidity,
                liquidityOperator
            );
    }

    function setPLPLpTimeCommitment(
        uint256 startingBlock,
        uint256 endingBlock,
        ILiquidityOperator liquidityOperator
    ) external returns (LPTimeCommitment memory) {
        return
            LPTimeCommitmentLibrary.setPLPLpTimeCommitment(
                startingBlock,
                endingBlock,
                liquidityOperator
            );
    }
    function validateLPType(
        LPTimeCommitment memory enteredTimeCommitment
    ) external pure {
        enteredTimeCommitment.validateLPType();
    }

    function validateTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) external view {
        enteredTimeCommitment.validateTimeCommitment();
    }

    function validatePLPTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) external view {
        enteredTimeCommitment.validatePLPTimeCommitment();
    }

    function validateJITTimeCommitment(
        LPTimeCommitment memory enteredTimeCommitment
    ) external view {
        enteredTimeCommitment.validateJITTimeCommitment();
    }

    function validateLPTypeOperator(
        LPTimeCommitment memory enteredTimeCommitment
    ) external {
        enteredTimeCommitment.validateLPTypeOperator();
    }
}
