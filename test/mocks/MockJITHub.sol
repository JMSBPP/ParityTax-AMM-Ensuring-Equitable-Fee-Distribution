//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IJITHub} from "../../src/interfaces/IJITHub.sol";
import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol"; 

import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {LiquidityMath} from "@uniswap/v4-core/src/libraries/LiquidityMath.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";


contract MockJITHub is IJITHub{
    using SafeCast for *;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;    
    using SqrtPriceMath for uint160;
    // NOTE: The JIT Operators are identified by their positionKey


    //NOTE: This is a placeHolder for testing
    address jitResolver;
    mapping(PoolId poolId => bytes32 positionKey) private jitOperators;

    IPoolManager poolManager;
    constructor(IPoolManager _manager) {
        poolManager = _manager;
    }

    function whiteListResolver(
        address _resolver
    ) internal {
        jitResolver = _resolver;
    }

    function fulfillTrade(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory jitLiquidityParams
    ) external {
        // TODO Request to the whitelisted JIT Operators to fill the liquidity
        // And this can even be an integration with 1 Inch ...
        // Now we are requesting the Resolvers to fill the trade ...

        // JIT Operators == 1 Inch Limit Orders Resolvers

        (uint256 liquidity0, uint256 liquidity1,) = _queryJITAmounts(poolKey, jitLiquidityParams);
        {
            //========APROVE THE HOOK TO MANAGE THE AGGREGATE JIT LIQUIDITY ==========
            IERC20(Currency.unwrap(poolKey.currency0)).approve(address(poolKey.hooks),liquidity0);
            IERC20(Currency.unwrap(poolKey.currency1)).approve(address(poolKey.hooks),liquidity1);
        
        }
        {
            //=======REQUEST THE AGGREGATE JIT LIQUIDITY FROM RESOLVERS ===========
            //                           ...
        }


        // NOTE: For testing purposes let's do only one Resolver filling trades
        // and this resolver being the current contract
    }

    function _queryJITAmounts(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory jitLiquidityParams
    ) internal returns(uint256 liquidity0, uint256 liquidity1, uint128 newLiquidity){
        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,int24 tick,,) = poolManager.getSlot0(poolId);
        (int24 tickLower, int24 tickUpper) = (
            jitLiquidityParams.tickLower,
            jitLiquidityParams.tickUpper
        );
        uint128 liquidity = poolManager.getLiquidity(poolId);
        int256 liquidityDelta = jitLiquidityParams.liquidityDelta;
        BalanceDelta delta;
        if (tick < tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ currency0 (it's becoming more valuable) so user must provide it
                delta = toBalanceDelta(
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount0Delta(
                        TickMath.getSqrtPriceAtTick(tickUpper),
                        liquidityDelta.toInt128().toUint128(),
                        false
                    ).toInt128(),
                    int128(0x00)
                );
            } else if (tick < tickUpper) {
                delta = toBalanceDelta(
                    sqrtPriceX96.getAmount0Delta(TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta.toInt128().toUint128(), false)
                        .toInt128(),
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount1Delta(sqrtPriceX96, liquidityDelta.toInt128().toUint128(), false)
                        .toInt128()
                );

                newLiquidity = LiquidityMath.addDelta(liquidity, liquidityDelta.toInt128());
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ currency1 (it's becoming more valuable) so user must provide it
                delta = toBalanceDelta(
                    0,
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount1Delta(
                        TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta.toInt128().toUint128(), false
                    ).toInt128()
                );
            }

            (liquidity0, liquidity1) = (
                delta.amount0() < 0 ? uint256(uint128(-delta.amount0())) : uint256(delta.amount0().toUint128()),
                delta.amount1() < 0 ? uint256(uint128(-delta.amount1())) : uint256(delta.amount1().toUint128())
            );

        }
}