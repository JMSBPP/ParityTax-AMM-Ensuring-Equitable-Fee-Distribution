// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    PoolKey,
    SwapParams
} from "@uniswap/v4-core/src/types/PoolOperation.sol";

interface ILiquidityMetrics{

    function getSwapPLPLiquidity(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper 
    ) external view returns(uint128);


    function getSwapJITLiquidity(
        PoolKey memory poolKey,
        SwapParams memory swapParams,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns(uint128);


}
