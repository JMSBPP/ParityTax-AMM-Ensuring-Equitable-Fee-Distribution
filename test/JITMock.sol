// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {JIT} from "../src/JIT.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

contract JITMock is JIT {
    function jitAmounts(
        PoolKey calldata key,
        SwapParams calldata params,
        bytes memory data
    ) external returns (int128, int128) {
        return _jitAmounts(key, params, data);
    }
}
