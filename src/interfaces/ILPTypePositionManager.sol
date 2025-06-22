// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";

// interface IPositionManager is
//     INotifier,
//     IImmutableState,
//     IERC721Permit_v4,
//     IEIP712_v4,
//     IMulticall_v4,
//     IPoolInitializer_v4,
//     IUnorderedNonce,
//     IPermit2Forwarder
// {

interface ILPTypePositionManager is IPositionManager {}
