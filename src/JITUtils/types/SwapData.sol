// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SwapParams} from "v4-core/types/PoolOperation.sol";

/// @title SwapData
/// @author j-money-11
/// @notice A struct to hold historical swap data for a pool.
/// @dev This can be used for analysis and to inform future JIT liquidity decisions.
struct SwapData {
    SwapParams[] poolSwaps;
}

/// @title SwapDataLibrary
/// @author j-money-11
/// @notice A library for handling operations related to the SwapData struct.
/// @dev This library is currently a placeholder for future functionality.
library SwapDataLibrary {}