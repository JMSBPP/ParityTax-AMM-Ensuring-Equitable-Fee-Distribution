// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/PoolOperation.sol";
import {BeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";
import {IImmutableState} from "v4-periphery/src/interfaces/IImmutableState.sol";

interface IJIT is IImmutableState {
    function beforeSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata
    ) external returns (bytes4, BeforeSwapDelta, uint24);

    function afterSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external returns (bytes4, int128);
}
