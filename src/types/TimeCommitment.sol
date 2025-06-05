// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

struct TimeCommitment {
    address liquidityProvider;
    bool longTerm;
    uint256 numberOfBlocks;
    uint256 startingBlockNumber;
}

library TimeCommitmentLibrary {
    function getDuration(
        TimeCommitment memory commitment
    ) internal view returns (uint256 duration) {
        duration = commitment.startingBlockNumber + commitment.numberOfBlocks;
    }

    function enforceJITConditions(
        TimeCommitment memory commitment
    ) internal returns (TimeCommitment memory JITTimeCommitment) {
        if (!(commitment.longTerm)) {
            JITTimeCommitment = TimeCommitment({
                liquidityProvider: commitment.liquidityProvider,
                longTerm: false,
                numberOfBlocks: 1,
                startingBlockNumber: block.number
            });
        }
    }
}
