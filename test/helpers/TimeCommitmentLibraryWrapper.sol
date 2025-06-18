// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/TimeCommitment.sol";

/// @title TimeCommitmentLibraryWrapper
/// @notice A wrapper contract for the TimeCommitment library.
/// @dev This contract is used to test the library because of the issue
/// https://github.com/foundry-rs/foundry/issues/3437#issuecomment-1267029138
contract TimeCommitmentLibraryWrapper {
    using TimeCommitmentLibrary for *;

    constructor() {}

    /// @notice Validates a time commitment.
    /// @param isJIT Whether the commitment is a JIT commitment or not.
    /// @param startingBlock The block number when the commitment starts.
    /// @param endingBlock The block number when the commitment ends.
    /// @return validatedTimeCommitment The validated time commitment.
    function setTimeCommitment(
        bool isJIT,
        uint256 startingBlock,
        uint256 endingBlock
    ) external view returns (TimeCommitment memory validatedTimeCommitment) {
        return isJIT.setTimeCommitment(startingBlock, endingBlock);
    }

    /// @notice Calculates the duration of a TimeCommitment.
    /// @dev This function calculates the duration of a TimeCommitment.
    /// @param timeCommitment The TimeCommitment to calculate the duration of.
    /// @return commitmmentDuration The duration of the TimeCommitment.
    function getDuration(
        TimeCommitment memory timeCommitment
    ) external view returns (uint256 commitmmentDuration) {
        return timeCommitment.getDuration();
    }

    /// @notice Calculates the remaining commitment of a TimeCommitment.
    /// @dev This function calculates the remaining commitment of a TimeCommitment.
    /// @param timeCommitment The TimeCommitment to calculate the remaining commitment of.
    /// @return remainingCommitment The remaining commitment as a uint256.
    function getRemainingCommitment(
        TimeCommitment memory timeCommitment
    ) external view returns (uint256 remainingCommitment) {
        remainingCommitment = timeCommitment.getRemainingCommitment();
    }

    /**
     * @notice Encodes a TimeCommitment to bytes.
     * @param timeCommitment The TimeCommitment to encode.
     * @return encodedTimeCommitment The encoded TimeCommitment as bytes.
     */
    function toBytes(
        TimeCommitment memory timeCommitment
    ) external view returns (bytes memory encodedTimeCommitment) {
        encodedTimeCommitment = timeCommitment.toBytes();
    }

    /**
     * @notice Decodes a TimeCommitment from bytes.
     * @dev This function decodes a TimeCommitment from bytes.
     * @param rawData The bytes data to decode.
     * @return timeCommitment The decoded TimeCommitment.
     */
    function fromBytesToTimeCommitment(
        bytes memory rawData
    ) external view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = rawData.fromBytesToTimeCommitment();
    }
}
