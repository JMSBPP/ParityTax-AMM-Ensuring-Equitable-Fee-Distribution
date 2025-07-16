// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {console} from "forge-std/Test.sol";

/// @title TimeCommitment Library
/// @author j-money-11
/// @notice A library for handling time-based liquidity commitments.
/// It defines a custom type `TimeCommitment` that packs a timestamp and a commitment duration
/// into a single uint96 value. This is used to differentiate between different types of
/// liquidity providers (PLP, JIT) and manage their position states.
///
/// The structure of a TimeCommitment is:
/// - The most significant 48 bits store the block.timestamp when the commitment was made.
/// - The least significant 48 bits store the time commitment value (duration).

type TimeCommitment is uint96;

using {lt as <, gt as >} for TimeCommitment global;
using TimeCommitmentLibrary for TimeCommitment global;

using SafeCast for uint96;


error InvalidOperation___NotComperableTimeCommitments();



uint48 constant UNINITIALIZED_FLAG = 0x00;


uint48 constant JIT_FLAG = 0xffffffffffff;


function PLP(TimeCommitment timeCommitment) pure returns (bool plp) {
    plp =
        timeCommitmentValue(timeCommitment) > UNINITIALIZED_FLAG &&
        timeCommitmentValue(timeCommitment) < JIT_FLAG;
}





function JIT(TimeCommitment timeCommitment) pure returns (bool jit) {
    jit = timeCommitmentValue(timeCommitment) == JIT_FLAG;
}



function UNINITIALIZED(
    TimeCommitment timeCommitment
) pure returns (bool uninitialized) {
    uninitialized =
        timeCommitmentValue(timeCommitment) == UNINITIALIZED_FLAG ||
        timeStamp(timeCommitment) == 0x00;
}



function PLP_EXPIRED(
    TimeCommitment timeCommitment
) view returns (bool _plpExpired) {
    _plpExpired =
        PLP(timeCommitment) &&
        uint256(timeCommitmentValue(timeCommitment)) <= block.timestamp;
}


function PLP_NOT_EXPIRED(
    TimeCommitment timeCommitment
) view returns (bool _plpNotExpired) {
    _plpNotExpired =
        PLP(timeCommitment) &&
        uint256(timeCommitmentValue(timeCommitment)) > block.timestamp;
}



function timeStamp(TimeCommitment timeCommitment) pure returns (uint48) {
    uint48 _timeStamp;
    assembly ("memory-safe") {
        let ts := shr(48, timeCommitment)
        _timeStamp := ts
    }
    return _timeStamp;
}


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


function lt(TimeCommitment t1, TimeCommitment t2) pure returns (bool _lt) {
    _lt = timeStamp(t1) <= timeStamp(t2);
}


function gt(TimeCommitment t1, TimeCommitment t2) pure returns (bool _gt) {
    _gt = timeStamp(t1) >= timeStamp(t2);
}

function toTimeCommitment(uint48 timeCommitment) view returns (TimeCommitment) {
    uint48 blockTimestamp = uint48(block.timestamp);
    return
        TimeCommitment.wrap(
            (uint96(blockTimestamp) << 48) | uint96(timeCommitment)
        );
}


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

/// @title TimeCommitmentLibrary
/// @notice A library for operations on TimeCommitment instances.
library TimeCommitmentLibrary {
    /// @notice Sets/updates the timestamp of a TimeCommitment to the current block.timestamp.
    /// @param self The TimeCommitment instance.
    /// @return timeCommitment The updated TimeCommitment.
    function set(
        TimeCommitment self
    ) internal view returns (TimeCommitment timeCommitment) {
        timeCommitment = toTimeCommitment(timeCommitmentValue(self));
    }
}