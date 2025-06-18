// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
uint256 constant TIME_COMMITMENT_SIZE = 96; //60

/**
 * @title TimeCommitment
 * @notice A struct representing a time commitment from a LP.
 * @dev A time commitment is a commitment from a LP to provide liquidity
 * to a pool for a certain amount of blocks.
 */
struct TimeCommitment {
    /**
     * @dev Whether the commitment is a JIT commitment or not.
     * A JIT commitment is a commitment that starts in the next block.
     */
    bool isJIT;
    /**
     * @dev The block number when the commitment starts.
     */
    uint256 startingBlock;
    /**
     * @dev The block number when the commitment ends.
     */
    uint256 endingBlock;
}

/**
 * @dev Thrown when a time commitment's starting block is in the past.
 */
error InvalidTimeCommitment__BlockAlreadyPassed();

/**
 * @dev Thrown when a time commitment's starting block is after its ending block.
 */

//TODO: We need to determine a maximum liquidityCommitment
// not enforcing for "inifinite" commitments

error InvalidTimeCommitment__StartingBlockGreaterOrEqualThanEndingBlock();
error InvalidRawData___RawDataDoesNotDecodeToTimeCommitment();

/**
 * @title TimeCommitmentLibrary
 * @notice A library for manipulating TimeCommitments.
 * @dev This library provides functions for calculating the duration of a TimeCommitment,
 * validating a TimeCommitment, and more.
 */
library TimeCommitmentLibrary {
    function setTimeCommitment(
        bool isJIT,
        uint256 startingBlock,
        uint256 endingBlock
    ) internal view returns (TimeCommitment memory validatedTimeCommitment) {
        // 1. Check basic block number validity
        if (startingBlock < block.number) {
            revert InvalidTimeCommitment__BlockAlreadyPassed();
        }
        if (isJIT) {
            validatedTimeCommitment = TimeCommitment({
                isJIT: true,
                startingBlock: startingBlock,
                endingBlock: startingBlock
            });
        } else if (!isJIT) {
            if (endingBlock <= startingBlock) {
                revert InvalidTimeCommitment__StartingBlockGreaterOrEqualThanEndingBlock();
            } else {
                validatedTimeCommitment = TimeCommitment({
                    isJIT: false,
                    startingBlock: startingBlock,
                    endingBlock: endingBlock
                });
            }
        }
    }

    /**
     * @dev Calculates the duration of a TimeCommitment.
     * @param timeCommitment The TimeCommitment to calculate the duration of.
     * @return commitmmentDuration The duration of the TimeCommitment.
     */
    function getDuration(
        TimeCommitment memory timeCommitment
    ) internal view returns (uint256 commitmmentDuration) {
        TimeCommitment memory validatedTimeCommitment = setTimeCommitment(
            timeCommitment.isJIT,
            timeCommitment.startingBlock,
            timeCommitment.endingBlock
        );
        commitmmentDuration = validatedTimeCommitment.isJIT
            ? 0
            : validatedTimeCommitment.endingBlock -
                validatedTimeCommitment.startingBlock;
    }

    /**
     * @dev Calculates the remaining commitment of a TimeCommitment.
     *      The remaining commitment is the difference between the ending block of the commitment and the current block number.
     * @param timeCommitment The TimeCommitment to calculate the remaining commitment of.
     * @return remainingCommitment The remaining commitment as a uint256.
     */
    // @note The remaining commitment can be lower than 256 bits.
    function getRemainingCommitment(
        TimeCommitment memory timeCommitment
    ) internal view returns (uint256 remainingCommitment) {
        TimeCommitment memory validatedTimeCommitment = setTimeCommitment(
            timeCommitment.isJIT,
            timeCommitment.startingBlock,
            timeCommitment.endingBlock
        );
        remainingCommitment = validatedTimeCommitment.isJIT
            ? 0
            : validatedTimeCommitment.endingBlock - block.number;
    }

    /**
     * @dev Encodes a TimeCommitment to bytes.
     * @param timeCommitment The TimeCommitment to encode.
     * @return encodedTimeCommitment The encoded TimeCommitment as bytes.
     */
    function toBytes(
        TimeCommitment memory timeCommitment
    ) internal view returns (bytes memory encodedTimeCommitment) {
        TimeCommitment memory validatedTimeCommitment = setTimeCommitment(
            timeCommitment.isJIT,
            timeCommitment.startingBlock,
            timeCommitment.endingBlock
        );
        encodedTimeCommitment = abi.encode(validatedTimeCommitment);
    }

    /**
     * @dev Decodes a TimeCommitment from bytes.
     * @param rawData The bytes data to decode.
     * @return timeCommitment The decoded TimeCommitment.
     */
    function fromBytesToTimeCommitment(
        bytes memory rawData
    ) internal view returns (TimeCommitment memory timeCommitment) {
        if (rawData.length != TIME_COMMITMENT_SIZE) {
            revert InvalidRawData___RawDataDoesNotDecodeToTimeCommitment();
        }

        TimeCommitment memory uncheckedTimeCommitment = abi.decode(
            rawData,
            (TimeCommitment)
        );

        timeCommitment = setTimeCommitment(
            uncheckedTimeCommitment.isJIT,
            uncheckedTimeCommitment.startingBlock,
            uncheckedTimeCommitment.endingBlock
        );
    }
}
