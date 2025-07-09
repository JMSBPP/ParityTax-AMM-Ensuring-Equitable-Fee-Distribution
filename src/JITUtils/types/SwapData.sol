// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SwapParams} from "v4-core/types/PoolOperation.sol";

struct SwapData {
    SwapParams[] poolSwaps;
}

library SwapDataLibrary {}
