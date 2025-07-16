// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {console} from "forge-std/Test.sol";

/**
 * @title TimeCommitment Library
 * @author j-money-11
 * @notice A library for handling time-based liquidity commitments.
 * It defines a custom type `TimeCommitment` that packs a timestamp and a commitment duration
 * into a single uint96 value. This is used to differentiate between different types of
 * liquidity providers (PLP, JIT) and manage their position states.
 *
 * The structure of a TimeCommitment is:
 * - The most significant 48 bits store the block.timestamp when the commitment was made.
 * - The least significant 48 bits store the time commitment value (duration).
 */

type TimeCommitment is uint96;

using {lt as <, gt as >} for TimeCommitment global;
using TimeCommitmentLibrary for TimeCommitment global;

using SafeCast for uint96;

/// @dev Error thrown when trying to perform an operation on two incompatible TimeCommitments.
error InvalidOperation___NotComperableTimeCommitments();

/**
 * @notice Represents an uninitialized time commitment.
 * This is the default state before any commitment is made.
 */
uint48 constant UNINITIALIZED_FLAG = 0x00;

/**
 * @notice Represents a Just-In-Time (JIT) liquidity commitment.
 * This is a special value to identify JIT providers who are not subject to time locks.
 */
uint48 constant JIT_FLAG = 0xffffffffffff;

/**
 * @notice Checks if a time commitment belongs to a Provisioned Liquidity Provider (PLP).
 * @param timeCommitment The time commitment to check.
 * @return plp True if the commitment is for a PLP, false otherwise.
 * @dev A PLP commitment has a value greater than UNINITIALIZED_FLAG and less than JIT_FLAG.
 */
function PLP(TimeCommitment timeCommitment) pure returns (bool plp) {
    plp =
        timeCommitmentValue(timeCommitment) > UNINITIALIZED_FLAG &&
        timeCommitmentValue(timeCommitment) < JIT_FLAG;
}

/**
 * @notice Checks if a time commitment is for a Just-In-Time (JIT) provider.
 * @param timeCommitment The time commitment to check.
 * @return jit True if the commitment is for a JIT provider, false otherwise.
 */
function JIT(TimeCommitment timeCommitment) pure returns (bool jit) {
    jit = timeCommitmentValue(timeCommitment) == JIT_FLAG;
}

/**
 * @notice Checks if a time commitment is uninitialized.
 * @param timeCommitment The time commitment to check.
 * @return uninitialized True if the commitment is uninitialized, false otherwise.
 */
function UNINITIALIZED(
    TimeCommitment timeCommitment
) pure returns (bool uninitialized) {
    uninitialized =
        timeCommitmentValue(timeCommitment) == UNINITIALIZED_FLAG ||
        timeStamp(timeCommitment) == 0x00;
}

/**
 * @notice Checks if a PLP's time commitment has expired.
 * @param timeCommitment The time commitment to check.
 * @return _plpExpired True if the PLP commitment has expired, false otherwise.
 */
function PLP_EXPIRED(
    TimeCommitment timeCommitment
) view returns (bool _plpExpired) {
    _plpExpired =
        PLP(timeCommitment) &&
        uint256(timeCommitmentValue(timeCommitment)) <= block.timestamp;
}

/**
 * @notice Checks if a PLP's time commitment has not expired.
 * @param timeCommitment The time commitment to check.
 * @return _plpNotExpired True if the PLP commitment has not expired, false otherwise.
 */
function PLP_NOT_EXPIRED(
    TimeCommitment timeCommitment
) view returns (bool _plpNotExpired) {
    _plpNotExpired =
        PLP(timeCommitment) &&
        uint256(timeCommitmentValue(timeCommitment)) > block.timestamp;
}

/**
 * @notice Extracts the timestamp from a time commitment.
 * @param timeCommitment The time commitment.
 * @return uint48 The block timestamp when the commitment was made.
 */
function timeStamp(TimeCommitment timeCommitment) pure returns (uint48) {
    uint48 _timeStamp;
    assembly ("memory-safe") {
        let ts := shr(48, timeCommitment)
        _timeStamp := ts
    }
    return _timeStamp;
}

/**
 * @notice Extracts the commitment value (duration) from a time commitment.
 * @param timeCommitment The time commitment.
 * @return uint48 The value of the time commitment.
 */
function timeCommitmentValue(
    TimeCommitment timeCommitment
) pure returns (uint48) {
    uint96 timeCommitmentX96 = TimeCommitment.unwrap(timeCommitment);
    uint48 _timeCommitmentValue;
    assembly ("memory-safe") {
        _timeCommitmentValue := and(timeCommitmentX96, 0xFFFFFFFFFFFF)
    }
    return _timeCommitmentValue;
}

/**
 * @notice Compares two time commitments to see if the first is less than the second.
 * @dev Comparison is based on the timestamp.
 * @param t1 The first time commitment.
 * @param t2 The second time commitment.
 * @return _lt True if t1's timestamp is less than or equal to t2's.
 */
function lt(TimeCommitment t1, TimeCommitment t2) pure returns (bool _lt) {
    _lt = timeStamp(t1) <= timeStamp(t2);
}

/**
 * @notice Compares two time commitments to see if the first is greater than the second.
 * @dev Comparison is based on the timestamp.
 * @param t1 The first time commitment.
 * @param t2 The second time commitment.
 * @return _gt True if t1's timestamp is greater than or equal to t2's.
 */
function gt(TimeCommitment t1, TimeCommitment t2) pure returns (bool _gt) {
    _gt = timeStamp(t1) >= timeStamp(t2);
}

/**
 * @notice Creates a new TimeCommitment instance.
 * @param timeCommitment The duration of the commitment.
 * @return TimeCommitment The new TimeCommitment object.
 * @dev The timestamp is set to the current block.timestamp.
 */
function toTimeCommitment(uint48 timeCommitment) view returns (TimeCommitment) {
    uint48 blockTimestamp = uint48(block.timestamp);
    return
        TimeCommitment.wrap(
            (uint96(blockTimestamp) << 48) | uint96(timeCommitment)
        );
}
/**
 * @notice Adds two time commitments together.
 * @dev This function handles the logic for combining commitments, such as extending a PLP commitment
 * or transitioning a JIT commitment to a PLP. It optimistically adds them regardless of their expiry status.
 * @param t1 The first time commitment.
 * @param t2 The second time commitment.
 * @return t1Plust2 The resulting time commitment.
 */
function add(
    TimeCommitment t1,
    TimeCommitment t2
) returns (TimeCommitment t1Plust2) {
    if (lt(t1, t2)) {
        // NOTE: Not having any position allows to specify the lpType freely
        if (
            timeCommitmentValue(t1) == UNINITIALIZED_FLAG &&
            (timeCommitmentValue(t2) == JIT_FLAG || PLP(t2))
        ) {
            t1Plust2 = t2;
            // NOTE: Setting uninitialized when there is already a commitment, results
            // in ignoring the entered commitment
        } else if (timeCommitmentValue(t2) == UNINITIALIZED_FLAG) {
            t1Plust2 = t1;
            //NOTE: Adding  a PLP commitment to a PLP commitment is a PLP and follows
            // summing the timeCommitmentValues, NOT THE blockTimeStamps,

            // Since we are addding timeCommiments.
        } else if (
            PLP(t1) &&
            PLP(t2) &&
            PLP(
                toTimeCommitment(
                    timeCommitmentValue(t1) + timeCommitmentValue(t2)
                )
            )
        ) {
            // The timeStamp is the current block.timestamp.
            t1Plust2 = toTimeCommitment(
                timeCommitmentValue(t1) + timeCommitmentValue(t2)
            );
            //NOTE: Adding  a JIT commitment to a JIT commitment is a JIT
        } else if (
            timeCommitmentValue(t1) == JIT_FLAG &&
            timeCommitmentValue(t2) == JIT_FLAG
        ) {
            t1Plust2 = toTimeCommitment(JIT_FLAG);
            //NOTE: PLP's specifying JIT is equivalent to overriding the withdrawal lock
            // which would make the commitment useless, this needs to be avoided.
        } else if ((PLP(t1) && timeCommitmentValue(t2) == JIT_FLAG)) {
            revert InvalidOperation___NotComperableTimeCommitments();
            //NOTE: Since it's encouraged to be a PLP, then we should allow JIT's
            // to transition to a PLP
        } else if (timeCommitmentValue(t1) == JIT_FLAG && PLP(t2)) {
            t1Plust2 = t2;
        }
    } else if (lt(t2, t1)) {
        t1Plust2 = add(t2, t1);
    }
}

/**
 * @title TimeCommitmentLibrary
 * @notice A library for operations on TimeCommitment instances.
 */
library TimeCommitmentLibrary {
    /**
     * @notice Sets/updates the timestamp of a TimeCommitment to the current block.timestamp.
     * @param self The TimeCommitment instance.
     * @return timeCommitment The updated TimeCommitment.
     */
    function set(
        TimeCommitment self
    ) internal view returns (TimeCommitment timeCommitment) {
        timeCommitment = toTimeCommitment(timeCommitmentValue(self));
    }
}