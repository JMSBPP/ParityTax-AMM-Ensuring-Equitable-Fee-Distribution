//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



library TickPacking{

    /// @notice Packs two int24 ticks into a single bytes32 value for efficient storage.
    /// @param tickLower The lower tick.
    /// @param tickUpper The upper tick.
    /// @return A bytes32 value containing the packed ticks.
    function packTicks(int24 tickLower, int24 tickUpper) internal pure returns (bytes32) {
        // Cast to uint24 to get the raw bit patterns without sign extension.
        uint24 lower = uint24(tickLower);
        uint24 upper = uint24(tickUpper);

        // Combine into a uint48, then cast to a signed int48.
        int48 packedSigned = int48((uint48(lower) << 24) | uint48(upper));
        
        bytes32 packedResult;
        // Use assembly for the final, direct conversion to bytes32.
        assembly {
            packedResult := packedSigned
        }
        return packedResult;
    }

    /// @notice Unpacks two int24 ticks from a bytes32 value.
    /// @param packed The bytes32 value containing the packed ticks.
    /// @return tickLower The unpacked lower tick.
    /// @return tickUpper The unpacked upper tick.
    function unpackTicks(bytes32 packed) internal pure returns (int24 tickLower, int24 tickUpper) {
        // First, cast the bytes32 value to a signed 256-bit integer.
        int256 packedInt;
    // Use assembly to directly interpret the bytes32 data as an int256.
    assembly {
        packedInt := packed
    }

        // Right-shift to isolate the upper 24 bits. The sign is preserved.
        tickLower = int24(packedInt >> 24);
        
        // Casting to int24 truncates the upper bits, leaving only the lower tick.
        tickUpper = int24(packedInt);
    }
}