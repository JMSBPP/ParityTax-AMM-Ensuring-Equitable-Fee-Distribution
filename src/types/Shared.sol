//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";


struct JITData{
    PoolKey poolKey;
    SwapParams swapParams;
    uint256 amountOut;
    uint160 beforeSwapSqrtPriceX96;
    int24 expectedAfterSwapTick;

    uint128 plpLiquidity;
    uint160 expectedAfterSwapSqrtPriceX96;

}