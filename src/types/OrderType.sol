// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SwapParams} from "v4-core/types/PoolOperation.sol";

enum OrderLabel {
    NON_INFORMED,
    INFORMED,
    BACK_ARB
}

// NOTE: We are missing to deifne other
// data that can help a third -party
// mto determine the type of the order

struct OrderType {
    SwapParams swapParams;
    OrderLabel orderLabel;
}

library OrderTypeLibrary {}
