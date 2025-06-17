// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "../../src/types/TimeCommitment.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
contract TimeCommitmentTest is Test {
    using TimeCommitmentLibrary for *;

    function setUp() public {}

    function callValidateCommitment(
        bool _isJIT,
        uint256 _startingBlock,
        uint256 _endingBlock
    ) public view {
        TimeCommitmentLibrary.validateCommitment(
            _isJIT,
            _startingBlock,
            _endingBlock
        );
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
