// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
uint256 constant TIME_COMMITMENT_SIZE = 60;

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
error InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock();

//TODO: We need to determine a maximum liquidityCommitment
// not enforcing for "inifinite" commitments

error InvalidTimeCommitment__StartingBlockMustBeStrictlyLessThanEndingBlock();
error InvalidRawData___RawDataDoesNotDecodeToTimeCommitment();

/**
 * @title TimeCommitmentLibrary
 * @notice A library for manipulating TimeCommitments.
 * @dev This library provides functions for calculating the duration of a TimeCommitment,
 * validating a TimeCommitment, and more.
 */
library TimeCommitmentLibrary {
    //TODO: This can be a lower uint becasue durations
    // can not take that long

    /**
     * @dev Sets a TimeCommitment as a JIT (Just-In-Time) commitment.
     *      A JIT commitment is a commitment that is fulfilled at a specific block number.
     *      The starting block of the commitment is set to the same block number as the ending block.
     * @param startingBlock The TimeCommitment to set as a JIT commitment.
     * @return JIT_TimeCommitment The modified TimeCommitment with the starting block set to the same block number as the ending block.
     */
    function setJITCommitment(
        uint256 startingBlock
    ) internal view returns (TimeCommitment memory JIT_TimeCommitment) {
        JIT_TimeCommitment = TimeCommitment({
            isJIT: true,
            startingBlock: startingBlock,
            endingBlock: startingBlock
        });
    }

    function setPLPCommitment(
        uint256 startingBlock,
        uint256 endingBlock
    ) internal view returns (TimeCommitment memory PLP_TimeCommitment) {
        PLP_TimeCommitment = TimeCommitment({
            isJIT: false,
            startingBlock: startingBlock,
            endingBlock: endingBlock
        });
    }
    /**
     * @dev Calculates the duration of a TimeCommitment.
     * @param timeCommitment The TimeCommitment to calculate the duration of.
     * @return commitmmentDuration The duration of the TimeCommitment.
     */
    function getDuration(
        TimeCommitment memory timeCommitment
    ) internal view returns (uint256 commitmmentDuration) {
        TimeCommitment memory validatedTimeCommitment = validateCommitment(
            timeCommitment.isJIT,
            timeCommitment.startingBlock,
            timeCommitment.endingBlock
        );
        commitmmentDuration =
            validatedTimeCommitment.endingBlock -
            validatedTimeCommitment.startingBlock;
    }

    /**
     * @dev Checks if a TimeCommitment is a valid Perpetual Liquidity Provision (PLP) commitment.
     *      A valid PLP commitment is one that is not a JIT (Just-In-Time) commitment and has a starting block less than the ending block.
     * @param timeCommitment The TimeCommitment to check.
     * @return isValidPLPTimeCommitment True if the commitment is a valid PLP commitment, false otherwise.
     */
    function isPLPCommitment(
        TimeCommitment memory timeCommitment
    ) internal view returns (bool isValidPLPTimeCommitment) {
        isValidPLPTimeCommitment =
            timeCommitment.startingBlock ==
            setPLPCommitment(
                timeCommitment.startingBlock,
                timeCommitment.endingBlock
            ).startingBlock &&
            timeCommitment.endingBlock ==
            setPLPCommitment(
                timeCommitment.startingBlock,
                timeCommitment.endingBlock
            ).endingBlock &&
            !timeCommitment.isJIT;
    }

    function validateCommitment(
        bool isJIT,
        uint256 startingBlock,
        uint256 endingBlock
    ) internal view returns (TimeCommitment memory) {
        // 1. Check basic block number validity
        // if (startingBlock < block.number) {
        //     revert InvalidTimeCommitment__BlockAlreadyPassed();
        // }
        // if (endingBlock < startingBlock) {
        //     revert InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock();
        // }

        // 2. Check JIT/PLP consistency
        if (isJIT) {
            if (startingBlock != endingBlock) {
                // If marked JIT but blocks don't match, convert to proper JIT
                return setJITCommitment(startingBlock);
            }
        } else if (!isJIT) {
            if (startingBlock == endingBlock) {
                // If not marked JIT but single block, convert to PLP or revert
            } else {
                setPLPCommitment(startingBlock, endingBlock);
            }
        }
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
        TimeCommitment memory validatedTimeCommitment = validateCommitment(
            timeCommitment.isJIT,
            timeCommitment.startingBlock,
            timeCommitment.endingBlock
        );
        remainingCommitment =
            validatedTimeCommitment.endingBlock -
            block.number;
    }

    /**
     * @dev Encodes a TimeCommitment to bytes.
     * @param timeCommitment The TimeCommitment to encode.
     * @return encodedTimeCommitment The encoded TimeCommitment as bytes.
     */
    function toBytes(
        TimeCommitment memory timeCommitment
    ) internal view returns (bytes memory encodedTimeCommitment) {
        TimeCommitment memory validatedTimeCommitment = validateCommitment(
            timeCommitment.isJIT,
            timeCommitment.startingBlock,
            timeCommitment.endingBlock
        );
        encodedTimeCommitment = abi.encode(validatedTimeCommitment);
    }

    /**
     * @dev Decodes bytes to a TimeCommitment and validates the commitment.
     * @param rawData The encoded TimeCommitment as bytes.
     * @return timeCommitment The decoded and validated TimeCommitment.
     */
    function fromBytesToTimeCommitment(
        bytes memory rawData
    ) internal view returns (TimeCommitment memory timeCommitment) {
        if (rawData.length != TIME_COMMITMENT_SIZE) {
            revert InvalidRawData___RawDataDoesNotDecodeToTimeCommitment();
        }
        timeCommitment = validateCommitment(
            abi.decode(rawData, (TimeCommitment)).isJIT,
            abi.decode(rawData, (TimeCommitment)).startingBlock,
            abi.decode(rawData, (TimeCommitment)).endingBlock
        );
    }
}
