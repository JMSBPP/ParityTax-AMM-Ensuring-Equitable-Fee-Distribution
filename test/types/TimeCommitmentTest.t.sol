// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../../src/types/TimeCommitment.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
contract TimeCommitmentTest is Test {
    using TimeCommitmentLibrary for *;

    function setUp() public {}

    function test__FuzzyTimeCommitment(
        TimeCommitment memory timeCommitment,
        uint256 _currentBlock
    ) public {
        vm.assume(
            (_currentBlock < Constants.MAX_UINT256) &&
                (timeCommitment.startingBlock < Constants.MAX_UINT256) &&
                (timeCommitment.endingBlock < Constants.MAX_UINT256)
        );

        vm.roll(_currentBlock);

        if (timeCommitment.startingBlock < _currentBlock) {
            vm.expectRevert("InvalidTimeCommitment__BlockAlreadyPassed");
            timeCommitment.validateCommitment();
        } else if (timeCommitment.endingBlock < timeCommitment.startingBlock) {
            vm.expectRevert(
                "InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock()"
            );
            timeCommitment.validateCommitment();
        } else if (
            timeCommitment.startingBlock == timeCommitment.endingBlock &&
            !timeCommitment.isJIT
        ) {
            vm.expectRevert(
                "InvalidTimeCommitment__StartingBlockMustBeStrictlyLessThanEndingBlock()"
            );
            timeCommitment.validateCommitment();
        } else {
            timeCommitment.validateCommitment();
        }
    }

    // function test__FuzzRawDataDecodesToTimeCommitment(
    //     bytes memory rawData,
    //     uint256 _currentBlock
    // ) public {
    //     vm.assume((_currentBlock < Constants.MAX_UINT256));
    //     // 1. We need to decode the rawData to a TimeCommitment
    //     // and check that it is valid
    //     if (rawData.length != TIME_COMMITMENT_SIZE) {
    //         vm.expectRevert(
    //             InvalidRawData___RawDataDoesNotDecodeToTimeCommitment.selector
    //         );
    //         rawData.fromBytesToTimeCommitment();
    //     } else {
    //         test__FuzzyTimeCommitment(
    //             rawData.fromBytesToTimeCommitment(),
    //             _currentBlock
    //         );
    //     }
    // }
}
