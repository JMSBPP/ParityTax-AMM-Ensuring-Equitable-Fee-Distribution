// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
     * @dev Calculates the duration of a TimeCommitment.
     * @param timeCommitment The TimeCommitment to calculate the duration of.
     * @return commitmmentDuration The duration of the TimeCommitment.
     */
    function getDuration(
        TimeCommitment memory timeCommitment
    ) internal pure returns (uint256 commitmmentDuration) {
        commitmmentDuration =
            timeCommitment.endingBlock -
            timeCommitment.startingBlock;
    }

    /**
     * @dev Sets a TimeCommitment as a JIT (Just-In-Time) commitment.
     *      A JIT commitment is a commitment that is fulfilled at a specific block number.
     *      The starting block of the commitment is set to the same block number as the ending block.
     * @param timeCommitment The TimeCommitment to set as a JIT commitment.
     * @return JIT_TimeCommitment The modified TimeCommitment with the starting block set to the same block number as the ending block.
     */
    function setJITCommitment(
        TimeCommitment memory timeCommitment
    ) internal pure returns (TimeCommitment memory JIT_TimeCommitment) {
        if (timeCommitment.isJIT) {
            JIT_TimeCommitment = TimeCommitment({
                isJIT: true,
                startingBlock: timeCommitment.startingBlock,
                endingBlock: timeCommitment.startingBlock
            });
        }
    }

    /**
     * @dev Checks if a TimeCommitment is a valid Perpetual Liquidity Provision (PLP) commitment.
     *      A valid PLP commitment is one that is not a JIT (Just-In-Time) commitment and has a starting block less than the ending block.
     * @param timeCommitment The TimeCommitment to check.
     * @return isValidPLPTimeCommitment True if the commitment is a valid PLP commitment, false otherwise.
     */
    function isPLPCommitment(
        TimeCommitment memory timeCommitment
    ) internal pure returns (bool isValidPLPTimeCommitment) {
        if (!timeCommitment.isJIT) {
            isValidPLPTimeCommitment =
                timeCommitment.endingBlock > timeCommitment.startingBlock;
        }
    }

    /**
     * @dev Validates a TimeCommitment to ensure it is a valid commitment.
     *      A valid commitment is one that:
     *      - Has a starting block that is in the future
     *      - Has a starting block that is less than the ending block
     *      - Is not a JIT (Just-In-Time) commitment, or has a starting block that is equal to the ending block
     * @param timeCommitment The TimeCommitment to validate.
     */
    function validateCommitment(
        TimeCommitment memory timeCommitment
    ) internal view {
        if (block.number < timeCommitment.startingBlock)
            revert InvalidTimeCommitment__BlockAlreadyPassed();
        if (timeCommitment.endingBlock < timeCommitment.startingBlock)
            revert InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock();
        if (!isPLPCommitment(timeCommitment)) {
            setJITCommitment(timeCommitment);
        }
    }

    /**
     * @dev Encodes a TimeCommitment to bytes.
     * @param timeCommitment The TimeCommitment to encode.
     * @return encodedTimeCommitment The encoded TimeCommitment as bytes.
     */
    function toBytes(
        TimeCommitment memory timeCommitment
    ) internal pure returns (bytes memory encodedTimeCommitment) {
        encodedTimeCommitment = abi.encode(timeCommitment);
    }

    /**
     * @dev Decodes bytes to a TimeCommitment and validates the commitment.
     * @param encodedTimeCommitment The encoded TimeCommitment as bytes.
     * @return timeCommitment The decoded and validated TimeCommitment.
     */
    function fromBytesToTimeCommitment(
        bytes memory encodedTimeCommitment
    ) internal view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = abi.decode(encodedTimeCommitment, (TimeCommitment));
        validateCommitment(timeCommitment);
    }
}
