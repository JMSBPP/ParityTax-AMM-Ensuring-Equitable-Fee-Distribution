// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/TimeCommitment.sol";

contract TimeCommitmentLibraryWrapper {
    using TimeCommitmentLibrary for *;

    constructor() {}

    function setTimeCommitment(
        bool isJIT,
        uint256 startingBlock,
        uint256 endingBlock
    ) external view returns (TimeCommitment memory validatedTimeCommitment) {
        return isJIT.setTimeCommitment(startingBlock, endingBlock);
    }

    function getDuration(
        TimeCommitment memory timeCommitment
    ) external view returns (uint256 commitmmentDuration) {
        return timeCommitment.getDuration();
    }

    function getRemainingCommitment(
        TimeCommitment memory timeCommitment
    ) external view returns (uint256 remainingCommitment) {
        remainingCommitment = timeCommitment.getRemainingCommitment();
    }

    function toBytes(
        TimeCommitment memory timeCommitment
    ) external view returns (bytes memory encodedTimeCommitment) {
        encodedTimeCommitment = timeCommitment.toBytes();
    }

    function fromBytesToTimeCommitment(
        bytes memory rawData
    ) external view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = rawData.fromBytesToTimeCommitment();
    }
}
