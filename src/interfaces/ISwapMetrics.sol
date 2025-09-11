// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {
    PoolKey,
    SwapParams,
    BalanceDelta
} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import "../types/Shared.sol";

interface ISwapMetrics{


    function compareSwapOutput(
        PoolKey memory hookedKey,
        SwapParams memory swapParams,
        PoolKey memory comparedPoolKey
    ) external view returns(BalanceDelta delta);

    function simulateSwapOutputOnUnHookedPool(
        PoolKey memory hookedKey,
        SwapParams memory swapParams
    ) external returns(BalanceDelta delta, SwapOutput memory swapOutput);


    function simulatePriceImpact(
        PoolKey memory poolKey,
        uint160 initialSqrtPriceX96,
        uint128 liquidity,
        SwapParams memory swapParams,
        SwapOutput memory swapOutput
    ) external view returns(uint160,int24);


}

