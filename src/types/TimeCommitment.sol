// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//   8 bits    48 bits      8 bits             160 bits (address)
// LPType | endingBlock | optimalDuration | liquidityProvider
// enum LPType {
//     NONE,
//     JIT,
//     PLP
// }
// The occupied bits are 224, leaving 192 bits
// available for modularity implementations,
// This can be hook upgrades that require the hook data
// to be larger than 56 bytes
type TimeCommitment is bytes32;

using TimeCommitmentLibrary for TimeCommitment global;
library TimeCommitmentLibrary {
    uint256 internal constant MAX_ENDING_BLOCK = 0xffffffffffff;
    uint256 internal constant MAX_LP_TYPE = 0x02;

    //0x   ab     00000001   000000000000000000000000000000000000000000000000000000
    //   lpType  endingBlock

    // The first two bytes need to be either 1 or 2 to be a valid LPType

    function toTimeCommitment(
        bytes memory hookData
    ) internal view returns (TimeCommitment) {
        return
            TimeCommitment.wrap(
                bytes32(
                    uint256(
                        (uint56(endingBlock(hookData)) << 8) |
                            uint56(lpType(hookData))
                    )
                )
            );
        // we now must put endingBlock to the right of lpType
        // and pass the resulting bytes7 to bytes32
    }

    function toHookData(
        TimeCommitment self
    ) internal pure returns (bytes memory) {
        return abi.encode(TimeCommitment.unwrap(self));
    }

    function lpType(
        bytes memory hookData
    ) internal pure returns (uint8 castedLpType) {
        //NOTE: We wnat to enforce PLP positions
        // on the optimal duration, that is why the default value is
        // 0x02 which amps to PLP
        assembly ("memory-safe") {
            let dataPtr := add(hookData, 32)

            let firstByte := shr(248, mload(dataPtr))
            switch firstByte
            case 0x01 {
                castedLpType := 0x01
            }
            case 0x02 {
                castedLpType := 0x02
            }
            default {
                castedLpType := 0x02
            } // MAX_LP_TYPE is 2
        }
    }

    function endingBlock(
        bytes memory hookData
    ) internal view returns (uint48 _endingBlock) {
        // it retreives the uint48 from the 8 bit to the 56 bit
        // and if its is smaller than the currentc block.number
        // it assgins the current block.number to _currentBlock
        // otherwise it returns the extracted 58 bits casted to uint48

        uint48 extractedEndingBlock;
        if (hookData.length >= 0x07) {
            uint8 _lpType = lpType(hookData);
            assembly ("memory-safe") {
                let data := mload(add(hookData, 32))
                extractedEndingBlock := shr(208, shl(8, data))
            }
            if (_lpType == 0x01) {
                _endingBlock = uint48(block.number);
            } else if (_lpType == 0x02) {
                if (
                    extractedEndingBlock <= block.number ||
                    extractedEndingBlock >= MAX_ENDING_BLOCK
                ) {
                    _endingBlock = uint48(block.number + 1);
                } else {
                    _endingBlock = extractedEndingBlock;
                }
            }
        } else {
            _endingBlock = uint48(block.number + 1);
        }
    }

    function setOptimalDuration(
        TimeCommitment self,
        uint8 optimalDuration
    ) internal pure returns (TimeCommitment) {
        return
            TimeCommitment.wrap(
                bytes32(
                    uint256(
                        uint64(
                            uint256(TimeCommitment.unwrap(self)) &
                                0x00FFFFFFFFFFFFFF
                        ) | (uint64(optimalDuration) << 56)
                    )
                )
            );
    }
}
