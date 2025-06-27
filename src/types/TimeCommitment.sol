// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// NOTE TimeCommitment is a block.timestamp > currentTimeStamp
type TimeCommitment is uint256;

uint256 constant JIT = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
uint256 constant NO_EXIST = 0x0;

enum Tag {
    NO_EXIST,
    PLP_EXPIPRED,
    PLP_NOT_EXPIRED,
    JIT,
    INVALID
}

using TimeCommitmentLibrary for TimeCommitment global;

error InvalidTimeCommitment__LPMustSpecifyNonEmptyCommitment();
error InvalidLiquidityPositionState__LPMsutHaveValidTimeCommitment();
error InvalidTimeCommitment__IncompatibleTimeCommitmentTags();
library TimeCommitmentLibrary {
    function decodeTagAndReturnTimeCommitment(
        bytes memory encodedTimeCommitment
    ) internal view returns (TimeCommitment, Tag) {
        TimeCommitment timeCommitment = abi.decode(
            encodedTimeCommitment,
            (TimeCommitment)
        );
        return (timeCommitment, tagTimeCommitment(timeCommitment));
    }

    function validateTimeCommitmentTags(
        Tag existingTimeCommitmentTag,
        Tag enteredTimeCommitmentTag
    ) internal view returns (bool) {
        if (enteredTimeCommitmentTag == Tag.NO_EXIST) {
            revert InvalidTimeCommitment__LPMustSpecifyNonEmptyCommitment();
        }

        //2. If the enteredTimeCommitment is invalid then we must verify
        // what the validity of the currentTimeCommitment and act accordingly

        if (enteredTimeCommitmentTag == Tag.INVALID) {
            //2.1 If the existingTimeCommitment is invalid then we
            // need to custom revert
            if (existingTimeCommitmentTag == Tag.INVALID) {
                revert InvalidLiquidityPositionState__LPMsutHaveValidTimeCommitment();
            } else {
                if (
                    ((existingTimeCommitmentTag == Tag.PLP_EXPIPRED) ||
                        ((existingTimeCommitmentTag == Tag.PLP_NOT_EXPIRED) &&
                            (enteredTimeCommitmentTag == Tag.JIT))) ||
                    (existingTimeCommitmentTag == Tag.JIT &&
                        ((enteredTimeCommitmentTag == Tag.PLP_EXPIPRED) ||
                            (enteredTimeCommitmentTag == Tag.PLP_NOT_EXPIRED)))
                ) {
                    revert InvalidTimeCommitment__IncompatibleTimeCommitmentTags();
                }
            }
        }
        // If the enteredTimeCommitment is invalid and the existingTimeCommitment
    }

    function tagTimeCommitment(
        TimeCommitment timeCommitment
    ) internal view returns (Tag) {
        if (timeCommitment.notExistent()) return Tag.NO_EXIST;
        if (timeCommitment.isJIT()) return Tag.JIT;
        if (timeCommitment.isPLPExpired()) return Tag.PLP_EXPIPRED;
        if (timeCommitment.isPLPNotExpired()) return Tag.PLP_NOT_EXPIRED;
        return Tag.INVALID;
    }

    function decodeAndTagTimeCommitment(
        bytes memory encodedTimeCommitment
    ) internal view returns (Tag) {
        return
            abi
                .decode(encodedTimeCommitment, (TimeCommitment))
                .tagTimeCommitment();
    }

    function notExistent(
        TimeCommitment timeCommitment
    ) internal pure returns (bool) {
        return TimeCommitment.unwrap(timeCommitment) == NO_EXIST;
    }

    function isPLPNotExpired(
        TimeCommitment timeCommitment
    ) internal view returns (bool) {
        return TimeCommitment.unwrap(timeCommitment) > uint256(block.timestamp);
    }

    function isPLPExpired(
        TimeCommitment timeCommitment
    ) internal view returns (bool) {
        return ((TimeCommitment.unwrap(timeCommitment) <=
            uint256(block.timestamp)) && !isJIT(timeCommitment));
    }

    function isInvalid(
        TimeCommitment timeCommitment
    ) internal view returns (bool) {
        return
            !(isPLPExpired(timeCommitment) ||
                isPLPNotExpired(timeCommitment) ||
                isJIT(timeCommitment) ||
                notExistent(timeCommitment));
    }

    function isJIT(TimeCommitment timeCommitment) internal pure returns (bool) {
        return TimeCommitment.unwrap(timeCommitment) == JIT;
    }

    // TODO This function is managed by the TimeCommitmentControlled which signals
    // the optimal timeCommitment where visible liquidity is mostly appreciated by the system
    function isOptimal(
        TimeCommitment timeCommitment
    ) internal pure returns (bool) {
        return false;
    }
}
