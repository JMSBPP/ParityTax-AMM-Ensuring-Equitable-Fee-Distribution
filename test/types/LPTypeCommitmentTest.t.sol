// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/LPTimeCommmitmentSetUp.sol";
contract LPTypeCommitmentTest is LPTimeCommmitmentSetUp {
    function test__Unit__ValidateLPType() external {
        LPTimeCommitment memory invalidTimeCommitment = LPTimeCommitment({
            liquidityOperator: jitHook,
            lpType: LPType.NONE,
            startingBlock: 0,
            endingBlock: 0
        });
        vm.expectRevert("InvalidLPType___LPTypeMustBePLPOrJIT()");
        vm.startPrank(jit);

        lpTimeCommitmentLibrary.validateLPType(invalidTimeCommitment);
        vm.stopPrank();
        LPTimeCommitment memory validTimeCommitment = LPTimeCommitment({
            liquidityOperator: jitHook,
            lpType: LPType.JIT,
            startingBlock: 0,
            endingBlock: 0
        });
        vm.startPrank(jit);
        lpTimeCommitmentLibrary.validateLPType(validTimeCommitment);
        vm.stopPrank();
    }

    function test__Unit__validateLPTypeOperator() external {
        LPTimeCommitment memory invalidTimeCommitment = LPTimeCommitment({
            liquidityOperator: invalidOperator,
            lpType: LPType.JIT,
            startingBlock: 0,
            endingBlock: 0
        });
        vm.expectRevert(
            "InvalidOperator___LPTypeMustBeCompatibleWithOperatorType()"
        );
        vm.startPrank(jit);
        lpTimeCommitmentLibrary.validateLPTypeOperator(invalidTimeCommitment);
        vm.stopPrank();

        LPTimeCommitment memory validJITTimeCommitment = LPTimeCommitment({
            liquidityOperator: jitHook,
            lpType: LPType.JIT,
            startingBlock: 0,
            endingBlock: 0
        });
        vm.startPrank(jit);
        lpTimeCommitmentLibrary.validateLPTypeOperator(validJITTimeCommitment);
        vm.stopPrank();
        LPTimeCommitment memory validPLPTimeCommitment = LPTimeCommitment({
            liquidityOperator: plpOperator,
            lpType: LPType.PLP,
            startingBlock: 0,
            endingBlock: 0
        });
        vm.startPrank(plp);
        lpTimeCommitmentLibrary.validateLPTypeOperator(validPLPTimeCommitment);
        vm.stopPrank();
    }

    function test__Fuzz__validatedTimeCommitment(
        uint256 startingBlock,
        uint256 endingBlock,
        uint256 blockNumber,
        bool isJIT
    ) public returns (LPTimeCommitment memory validatedTimeCommitment) {
        bound(blockNumber, 0, type(uint256).max);
        vm.roll(blockNumber);
        assertEq(block.number, blockNumber);

        LPTimeCommitment memory enteredTimeCommitment = LPTimeCommitment({
            liquidityOperator: ILiquidityOperator(
                isJIT ? address(jitHook) : address(plpOperator)
            ),
            lpType: isJIT ? LPType.JIT : LPType.PLP,
            startingBlock: startingBlock,
            endingBlock: endingBlock
        });

        vm.startPrank(isJIT ? jit : plp);
        if (enteredTimeCommitment.startingBlock < block.number) {
            vm.expectRevert("InvalidTimeCommitment__BlockAlreadyPassed()");
            lpTimeCommitmentLibrary.validateTimeCommitment(
                enteredTimeCommitment
            );
        } else if (
            enteredTimeCommitment.endingBlock <
            enteredTimeCommitment.startingBlock
        ) {
            vm.expectRevert(
                "InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock()"
            );
            lpTimeCommitmentLibrary.validateTimeCommitment(
                enteredTimeCommitment
            );
        } else {
            lpTimeCommitmentLibrary.validateTimeCommitment(
                enteredTimeCommitment
            );
            validatedTimeCommitment = enteredTimeCommitment;
        }
        vm.stopPrank();
    }

    function test__Fuzz__validateLPTypeTimeCommitment(
        uint256 startingBlock,
        uint256 endingBlock,
        uint256 blockNumber,
        bool isJIT
    ) public returns (LPTimeCommitment memory validatedLPTypeTimeCommitment) {
        LPTimeCommitment
            memory validatedTimeCommitment = test__Fuzz__validatedTimeCommitment(
                startingBlock,
                endingBlock,
                blockNumber,
                isJIT
            );
        vm.startPrank(isJIT ? jit : plp);

        if (validatedTimeCommitment.lpType == LPType.PLP) {
            vm.expectRevert("InvalidLPType___LPTypeMustBeJIT()");
            lpTimeCommitmentLibrary.validateJITTimeCommitment(
                validatedTimeCommitment
            );
        } else if (
            (validatedTimeCommitment.lpType == LPType.JIT) &&
            (validatedTimeCommitment.startingBlock <
                validatedTimeCommitment.endingBlock)
        ) {
            vm.expectRevert(
                "InvalidJITTimeCommitment__StartingBlockMustBeEqualToEndingBlock()"
            );
            lpTimeCommitmentLibrary.validateJITTimeCommitment(
                validatedTimeCommitment
            );
        } else if (
            (validatedTimeCommitment.lpType == LPType.JIT) &&
            (validatedTimeCommitment.startingBlock ==
                validatedTimeCommitment.endingBlock)
        ) {
            lpTimeCommitmentLibrary.validateJITTimeCommitment(
                validatedTimeCommitment
            );
            validatedLPTypeTimeCommitment = lpTimeCommitmentLibrary
                .setJITLpTimeCommitment(
                    validatedTimeCommitment.startingBlock,
                    validatedTimeCommitment.liquidityOperator
                );
        } else if ((validatedTimeCommitment.lpType == LPType.JIT)) {
            vm.expectRevert("InvalidLPType___LPTypeMustBePLP()");
            lpTimeCommitmentLibrary.validatePLPTimeCommitment(
                validatedTimeCommitment
            );
        } else if (validatedTimeCommitment.lpType == LPType.PLP) {
            if (
                validatedTimeCommitment.startingBlock ==
                validatedTimeCommitment.endingBlock
            ) {
                vm.expectRevert(
                    "InvalidPLPTimeCommitment__EndingBlockMustBeStrictlyGreaterThanStartingBlock()"
                );
                lpTimeCommitmentLibrary.validatePLPTimeCommitment(
                    validatedTimeCommitment
                );
            } else if (
                validatedTimeCommitment.startingBlock <
                validatedTimeCommitment.endingBlock
            ) {
                lpTimeCommitmentLibrary.validatePLPTimeCommitment(
                    validatedTimeCommitment
                );
                validatedLPTypeTimeCommitment = lpTimeCommitmentLibrary
                    .setPLPLpTimeCommitment(
                        validatedTimeCommitment.startingBlock,
                        validatedTimeCommitment.endingBlock,
                        validatedTimeCommitment.liquidityOperator
                    );
            }
        }
        vm.stopPrank();
    }
    function test__Fuzz__validateAndSetLPTypeTimeCommitment(
        uint256 startingBlock,
        uint256 endingBlock,
        uint256 blockNumber,
        bool isJIT
    ) public returns (LPTimeCommitment memory validatedLPTypeTimeCommitment) {
        LPTimeCommitment
            memory _validatedLPTypeTimeCommitment = test__Fuzz__validateLPTypeTimeCommitment(
                startingBlock,
                endingBlock,
                blockNumber,
                isJIT
            );
        vm.startPrank(isJIT ? jit : plp);

        if (validatedLPTypeTimeCommitment.lpType == LPType.NONE) {
            vm.expectRevert("InvalidLPType___LPTypeMustBePLPOrJIT()");
            validatedLPTypeTimeCommitment = lpTimeCommitmentLibrary
                .validateAndSetLPTypeTimeCommitment(
                    _validatedLPTypeTimeCommitment
                );
        } else {
            validatedLPTypeTimeCommitment = lpTimeCommitmentLibrary
                .validateAndSetLPTypeTimeCommitment(
                    _validatedLPTypeTimeCommitment
                );
        }
        vm.stopPrank();
    }
}
