// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BeforeSwapDelta} from "v4-core/types/BeforeSwapDelta.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
interface IJITHook {
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4, BeforeSwapDelta, uint24);

    // TODO: The after swap is an afterSwapReturnDelta because this way we cna charge taxes on
    // the output token then, rather than enforrcing JITHooks to comply with an interface we need
    // JITHooks to be compliant to be compliant with an anstract contract, then ...
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4, int128);
}
