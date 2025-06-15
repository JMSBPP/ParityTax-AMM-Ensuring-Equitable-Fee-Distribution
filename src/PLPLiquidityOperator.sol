// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LiquidityOperator} from "./LiquidityOperator.sol";
import {IPLPHook} from "./hooks/interfaces/IPLPHook.sol";

abstract contract PLPLiquidityOperator is LiquidityOperator {
    IPLPHook private plpHook;
}
