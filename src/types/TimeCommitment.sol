// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

type TimeCommitment is uint96;
//NOTE Since we need to enforce the order of timeCommitments
// we define the timeCommitment as
// (uint48(timeCommitmentValue) | uint48 (block.timeStamp))
// --> uint48(block.timeStamp) where the timeCommmitment
// was entered

//NOTE The order of timeCommitments is ONLY important for PLP's
// timeCommitments, therefore we can define constants for

// UNINITIALIZED_TIME_COMMITMENT
// JIT

// NOTE: This values need to have block time stamps that are nots
//realistic in practice.abi

// NOTE: For both we choose thew same first "block.timeStamp" value
// as type(uint48).max -1
uint48 constant NOT_PLP_FLAG = 0xfffffffffffe;

// NOTE: For uninitalized timeCommitments we chose the last
// 48 bytes to be type(uintt48).max -2
uint48 constant UNINITIALIZED_TIME_COMMITMENT_FLAG = 0xfffffffffffd;
// NOTE: For uninitalized timeCommitments we chose the last
// 48 bytes to be type(uintt48).max -3
uint48 constant JIT_FLAG = 0xfffffffffffc;

// ========== CONSTANTS FOR NOT PLP TIME COMMITMENTS ========================
uint96 constant UNINITIALIZED_TIME_COMMITMENT = uint96(
    uint96((NOT_PLP_FLAG << 48)) | uint96(UNINITIALIZED_TIME_COMMITMENT_FLAG)
);

uint96 constant JIT = uint96(uint96(NOT_PLP_FLAG << 48) | uint96(JIT_FLAG));


error InvalidTimeCommitment___TimeCommitmentMustBePLP();

function toTimeCommitment(
    uint48 blockTimeStamp,
    uint48 timeCommitmentValue
) pure returns (TimeCommitment timeCommitment) {
    timeCommitment = TimeCommitment.wrap(
        uint96((blockTimeStamp << 48) | timeCommitmentValue)
    );
}
library TimeCommitmentlibrary {
    function isPLP(
        TimeCommitment timeCommitment
    ) internal pure returns (bool _isPLP) {
        uint96 unwrappedTimeCommitment = TimeCommitment.unwrap(timeCommitment);
        _isPLP =
            unwrappedTimeCommitment != JIT ||
            unwrappedTimeCommitment != UNINITIALIZED_TIME_COMMITMENT;
    }

    function isPLPExpired(
        TimeCommitment timeCommitment
    )internal view (bool _isPLPExpired) {
        if (!isPLP(timeCommitment)) revert InvalidTimeCommitment___TimeCommitmentMustBePLP();
        _isPLPExpired = uint256(TimeCommitment.unwrap(timeCommitment) >> 48) <= block.timeStamp ;
    }

    function isPLPNotExpired(
        TimeCommitment timeCommitment
    )internal view returns(bool _isPLPNotExpired) {
        _isPLPNotExpired = !isPLPExpired(timeCommitment);
    }
}
