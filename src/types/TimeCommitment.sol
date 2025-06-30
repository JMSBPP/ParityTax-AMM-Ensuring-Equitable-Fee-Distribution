// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
/*
@dev Two uint48, one representing, the blockTimeStamp where
the value was entered and the other one respresenting
the actual time commitment value
*/

type TimeCommitment is uint96;
using {lt as <, gt as >} for TimeCommitment global;
using SafeCast for uint96;

error NotComparableTimeCommitments___TimeCommitmentsMustBePLP();
error InvalidOperation___NotComperableTimeCommitments();
/*
uint48(block.timeStamp) | uint48(timeCommitmentValue)
*/

/*
@dev The first 48 bytes are a unrealistic timeStamp
this is type(uint48).max-1

@dev The last 48 bytes are unRealistic timeCommitment
this is type(uint48).max -2 
*/
// -------------------------->    NO_PLP_FLAG |  UNINIT_FLAG
uint96 constant UNINITIALIZED = 0xfffffffffffefffffffffffd;
// ----------------->    NO_PLP_FLAG |  JIT_FLAG
uint96 constant JIT = 0xfffffffffffefffffffffffe;
// NOTE We define < as only being valid for non uninitialized  or JIT'S
// time Commitment values, these are PLP's possible timeCommitment values
// and we have:
//

function PLP(TimeCommitment timeCommitment) pure returns (bool plp) {
    plp = TimeCommitment.unwrap(timeCommitment) < UNINITIALIZED;
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
    uint48 _timeCommitmentValue;
    assembly ("memory-safe") {
        let tv := shl(48, timeCommitment)
        _timeCommitmentValue := tv
    }
    return _timeCommitmentValue;
}

function lt(TimeCommitment t1, TimeCommitment t2) pure returns (bool _lt) {
    if (PLP(t1) && PLP(t2)) {
        _lt =
            timeStamp(t1) < timeStamp(t2) &&
            timeCommitmentValue(t1) < timeCommitmentValue(t2);
    } else {
        revert NotComparableTimeCommitments___TimeCommitmentsMustBePLP();
    }
}

function gt(TimeCommitment t1, TimeCommitment t2) pure returns (bool _gt) {
    if (PLP(t1) && PLP(t2)) {
        _gt =
            timeStamp(t1) > timeStamp(t2) &&
            timeCommitmentValue(t1) > timeCommitmentValue(t2);
    } else {
        revert NotComparableTimeCommitments___TimeCommitmentsMustBePLP();
    }
}

function toTimeCommitment(uint48 timeCommitment) view returns (TimeCommitment) {
    uint48 blockTimestamp = uint48(block.timestamp);
    return
        TimeCommitment.wrap(
            (uint96(blockTimestamp) << 48) | uint96(timeCommitment)
        );
}
//NOTE This function does not check for expiry PLP possitions but instead
// optimistically adds them regardless of their expirty status.

function add(
    TimeCommitment t1,
    TimeCommitment t2
) view returns (TimeCommitment t1Plust2) {
    if (lt(t1, t2)) {
        // NOTE: Not having any position allows to specify the lpType freely
        if (
            TimeCommitment.unwrap(t1) == UNINITIALIZED &&
            (TimeCommitment.unwrap(t2) == JIT || PLP(t2))
        ) {
            t1Plust2 = t2;
            // NOTE: Setting uninitialized when there is already a commitment, results
            // in ignoring the entered commitment
        } else if (TimeCommitment.unwrap(t2) == UNINITIALIZED) {
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
            TimeCommitment.unwrap(t1) == JIT && TimeCommitment.unwrap(t2) == JIT
        ) {
            t1Plust2 = TimeCommitment.wrap(JIT);
            //NOTE: PLP's specifying JIT is equivalent to overriding the withdrawal lock
            // which would make the commitment useless, this needs to be avoided.
        } else if ((PLP(t1) && TimeCommitment.unwrap(t2) == JIT)) {
            revert InvalidOperation___NotComperableTimeCommitments();
            //NOTE: Since it's encouraged to be a PLP, then we should allow JIT's
            // to transition to a PLP
        } else if (TimeCommitment.unwrap(t1) == JIT && PLP(t2)) {
            t1Plust2 = t2;
        }
    } else if (lt(t2, t1)) {
        t1Plust2 = add(t2, t1);
    }
}
