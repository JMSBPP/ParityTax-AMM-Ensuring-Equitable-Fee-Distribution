// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LiquidityOperator} from "./LiquidityOperator.sol";
import {IJITHook} from "./hooks/interfaces/IJITHook.sol";

abstract contract JITLiquidityOperator is LiquidityOperator {
    IJITHook private jitHook;
}
