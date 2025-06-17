// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../helpers/TimeCommitmentLibraryWrapper.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

contract TimeCommitmentTest is Test {
    using TimeCommitmentLibrary for *;

    TimeCommitmentLibraryWrapper timeCommitmentLibrary;
    function setUp() public {
        timeCommitmentLibrary = new TimeCommitmentLibraryWrapper();
    }

    function test__Unit__setJitTimeCommiment() external {
        vm.roll(100);
        bool isJIT = true;
        uint256 startingBlock = 101;
        uint256 endingBlock = 0;

        TimeCommitment memory jitTimeCommitment = timeCommitmentLibrary
            .setTimeCommitment(isJIT, startingBlock, endingBlock);
        assertEq(jitTimeCommitment.isJIT, isJIT);
        assertEq(jitTimeCommitment.startingBlock, startingBlock);
        assertEq(jitTimeCommitment.endingBlock, startingBlock);
        assertEq(
            0,
            timeCommitmentLibrary.getRemainingCommitment(jitTimeCommitment)
        );
        assertEq(0, timeCommitmentLibrary.getDuration(jitTimeCommitment));
    }
    function test__Unit__setPlpTimeCommitment() external {
        vm.roll(100);
        bool isJIT = true;
        bool isPLP = !isJIT;
        uint256 startingBlock = 101;
        uint256 endingBlock = 102;
        TimeCommitment memory plpTimeCommitment = timeCommitmentLibrary
            .setTimeCommitment(isPLP, startingBlock, endingBlock);
        assertEq(plpTimeCommitment.isJIT, isPLP);
        assertEq(plpTimeCommitment.startingBlock, startingBlock);
        assertEq(plpTimeCommitment.endingBlock, endingBlock);
        assertEq(
            endingBlock - block.number,
            timeCommitmentLibrary.getRemainingCommitment(plpTimeCommitment)
        );
        assertEq(
            endingBlock - startingBlock,
            timeCommitmentLibrary.getDuration(plpTimeCommitment)
        );
    }

    function test__Fuzz__setTimeCommitment(
        bool isJIT,
        uint256 startingBlock,
        uint256 endingBlock,
        uint256 blockNumber
    ) public {
        bound(blockNumber, uint256(100), uint256(type(uint160).max));
        vm.roll(blockNumber);
        if (startingBlock < block.number) {
            vm.expectRevert(InvalidTimeCommitment__BlockAlreadyPassed.selector);
            timeCommitmentLibrary.setTimeCommitment(
                isJIT,
                startingBlock,
                endingBlock
            );
        } else if (isJIT && startingBlock >= block.number) {
            TimeCommitment memory validJitTimeCommitment = timeCommitmentLibrary
                .setTimeCommitment(isJIT, startingBlock, endingBlock);
            assertEq(true, isJIT);
            assertEq(startingBlock, validJitTimeCommitment.startingBlock);
            assertEq(startingBlock, validJitTimeCommitment.endingBlock);
            assertEq(
                0,
                timeCommitmentLibrary.getRemainingCommitment(
                    validJitTimeCommitment
                )
            );
            assertEq(
                0,
                timeCommitmentLibrary.getDuration(validJitTimeCommitment)
            );
        } else if (!isJIT) {
            if (endingBlock <= startingBlock) {
                vm.expectRevert(
                    InvalidTimeCommitment__StartingBlockGreaterOrEqualThanEndingBlock
                        .selector
                );
                timeCommitmentLibrary.setTimeCommitment(
                    isJIT,
                    startingBlock,
                    endingBlock
                );
            } else {
                TimeCommitment
                    memory validPlpTimeCommitment = timeCommitmentLibrary
                        .setTimeCommitment(isJIT, startingBlock, endingBlock);
                assertEq(false, isJIT);
                assertEq(startingBlock, validPlpTimeCommitment.startingBlock);
                assertEq(endingBlock, validPlpTimeCommitment.endingBlock);
                assertEq(
                    endingBlock - block.number,
                    timeCommitmentLibrary.getRemainingCommitment(
                        validPlpTimeCommitment
                    )
                );
                assertEq(
                    endingBlock - startingBlock,
                    timeCommitmentLibrary.getDuration(validPlpTimeCommitment)
                );
            }
        }
    }

    function test__Unit__DecodeTimeCommitment() external {
        vm.roll(100);
        bytes memory garbage = bytes("garbageData");
        vm.expectRevert(
            InvalidRawData___RawDataDoesNotDecodeToTimeCommitment.selector
        );
        timeCommitmentLibrary.fromBytesToTimeCommitment(garbage);
        TimeCommitment memory validTimeCommitment = timeCommitmentLibrary
            .setTimeCommitment(false, 101, 200);

        bytes memory encodedTimeCommitment = abi.encode(validTimeCommitment);
        console.log(encodedTimeCommitment.length);
        TimeCommitment memory decodedTimeCommitment = timeCommitmentLibrary
            .fromBytesToTimeCommitment(encodedTimeCommitment);

        assertEq(validTimeCommitment.isJIT, decodedTimeCommitment.isJIT);
        assertEq(
            validTimeCommitment.startingBlock,
            decodedTimeCommitment.startingBlock
        );
        assertEq(
            validTimeCommitment.endingBlock,
            decodedTimeCommitment.endingBlock
        );
    }

    // function test__Fuzz__DecodeTimeCommitment(
    //     bytes memory rawData,
    //     uint256 blockNumber
    // ) external {
    //     TimeCommitment memory uncheckedTimeCommitment = timeCommitmentLibrary
    //         .fromBytesToTimeCommitmentUnchecked(rawData);
    //     console.log(uncheckedTimeCommitment.isJIT);
    //     console.log(uncheckedTimeCommitment.startingBlock);
    //     console.log(uncheckedTimeCommitment.endingBlock);
    // }
}
