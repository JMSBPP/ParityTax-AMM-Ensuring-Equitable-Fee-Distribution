// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPLPPositionManager} from "./interfaces/IPLPPositionManager.sol";

import {LPTypePositionManager} from "./LPTypePositionManager.sol";
abstract contract PLPPositionManager is
    LPTypePositionManager,
    IPLPPositionManager
{}
