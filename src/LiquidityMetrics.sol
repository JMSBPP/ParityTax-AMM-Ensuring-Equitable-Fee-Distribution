// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  "@uniswap/v4-core/src/types/BalanceDelta.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {
    ModifyLiquidityParams
} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";


import "./types/Shared.sol";

contract LiquidityMetrics is ImmutableState {
    using SqrtPriceMath for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    constructor(
        IPoolManager _poolManager
    ) ImmutableState(_poolManager){}

    function getSwapPLPLiquidity(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper 
    ) public returns(uint128){
        //NOTE: Make sure ticks are in order
        (int24 tickLower, int24 tickUpper) = _tickUpper < _tickLower ? (
            _tickUpper,
            _tickLower
        ) : (_tickLower, _tickUpper);

        PoolId poolId = poolKey.toId();

        uint24 tickRangeLength = uint24((tickUpper - tickLower) / poolKey.tickSpacing);

        int24 currentTick = tickLower;
        int128 totalLiquidity;

        while (currentTick <= tickUpper){
            (uint128 currentTickLiquidity,int128 currentTickLiquidityDelta) = poolManager.getTickLiquidity(
                poolId,
                currentTick
            );
            
            if (currentTick == tickLower){
                currentTickLiquidityDelta = int128(0x00);
            }

            totalLiquidity = int128(currentTickLiquidity) - currentTickLiquidityDelta;
            currentTick += int24(poolKey.tickSpacing); 

        }

        return uint128(totalLiquidity);

    }



}