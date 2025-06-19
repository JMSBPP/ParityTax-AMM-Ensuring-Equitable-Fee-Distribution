// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/interfaces/IImmutableState.sol";
import "v4-core/interfaces/callback/IUnlockCallback.sol";

interface ILiquidityTimeCommitmentRouter is IImmutableState, IUnlockCallback {}
