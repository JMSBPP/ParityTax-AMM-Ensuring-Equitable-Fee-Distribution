// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./LiquidityTimeCommitmentData.sol";

type PositionTimeCommitmentKey is bytes32;

library PositionTimeCommitmentKeyLibrary {
    function toPositionTimeCommitmentKey(
        bytes32 positionKey,
        TimeCommitment memory timeCommitment
    )
        internal
        pure
        returns (PositionTimeCommitmentKey positionTimeCommitmentKey)
    {
        positionTimeCommitmentKey = PositionTimeCommitmentKey.wrap(
            keccak256(
                abi.encodePacked(
                    positionKey,
                    timeCommitment.isJIT,
                    timeCommitment.startingBlock,
                    timeCommitment.endingBlock
                )
            )
        );
    }
}
