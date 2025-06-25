// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../../src/types/TimeCommitment.sol";

contract TimeCommitmentLibraryTest {
    using TimeCommitmentLibrary for *;

    function toTimeCommitment(
        bytes memory hookData
    ) external view returns (TimeCommitment) {
        return hookData.toTimeCommitment();
    }

    function toHookData(
        TimeCommitment self
    ) external pure returns (bytes memory) {
        return self.toHookData();
    }

    function lpType(
        bytes memory hookData
    ) external pure returns (uint8 castedLpType) {
        castedLpType = hookData.lpType();
    }
    function endingBlock(
        bytes memory hookData
    ) external view returns (uint48 _endingBlock) {
        _endingBlock = hookData.endingBlock();
    }

    function setOptimalDuration(
        TimeCommitment self,
        uint8 optimalDuration
    ) external pure returns (TimeCommitment) {
        return self.setOptimalDuration(optimalDuration);
    }
}
