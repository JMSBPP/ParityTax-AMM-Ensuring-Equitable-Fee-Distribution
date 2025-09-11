// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  "@uniswap/v4-core/src/types/BalanceDelta.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IV4Quoter,V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {
    SwapParams
} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";


import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";

import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";

import "./types/Shared.sol";
import "./interfaces/ISwapMetrics.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";


abstract contract SwapMetrics is ISwapMetrics{
    using SafeCast for *;
    using SqrtPriceMath for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;

    IV4Quoter v4Quoter;

    constructor(
        IV4Quoter _v4Quoter
    )
    {
        v4Quoter = _v4Quoter;
         
    }


    function compareSwapOutput(
        PoolKey memory hookedKey,
        SwapParams memory swapParams,
        PoolKey memory comparedPoolKey
    ) external view returns(BalanceDelta delta){
        delta = _compareSwapOutput(hookedKey, swapParams, comparedPoolKey);
    }


    function _compareSwapOutput(
        PoolKey memory hookedKey,
        SwapParams memory swapParams,
        PoolKey memory comparedPoolKey
    ) internal virtual view returns(BalanceDelta delta){
    }


    function simulateSwapOutputOnUnHookedPool(
        PoolKey memory hookedKey,
        SwapParams memory swapParams
    ) external returns(BalanceDelta delta, SwapOutput memory swapOutput){
        (delta, swapOutput) = _simulateSwapOutputOnUnHookedPool(hookedKey, swapParams);
    }


    function _simulateSwapOutputOnUnHookedPool(
        PoolKey memory hookedKey,
        SwapParams memory swapParams
    ) internal virtual returns(BalanceDelta delta, SwapOutput memory swapOutput){
        
        bool isExactInput = swapParams.amountSpecified <0;
        bool zeroForOne = swapParams.zeroForOne;
        PoolKey memory noHookKey = PoolKey({
                                currency0: hookedKey.currency0,
                                currency1: hookedKey.currency1,
                                fee: hookedKey.fee,
                                tickSpacing: hookedKey.tickSpacing,
                                hooks: IHooks(address(0x00))
                            });

        if (isExactInput){
                swapOutput.amountIn = uint256(-swapParams.amountSpecified);
                (swapOutput.amountOut,) = v4Quoter.quoteExactInputSingle(
                    IV4Quoter.QuoteExactSingleParams({
                        poolKey: noHookKey,
                        zeroForOne: swapParams.zeroForOne,
                        exactAmount: (-swapParams.amountSpecified).toInt128().toUint128(),
                        hookData: Constants.ZERO_BYTES
                    })
                );

            } else {
                (swapOutput.amountIn,) = v4Quoter.quoteExactOutputSingle(
                    IV4Quoter.QuoteExactSingleParams({
                        poolKey: noHookKey,
                        zeroForOne: swapParams.zeroForOne,
                        exactAmount: swapParams.amountSpecified.toInt128().toUint128(),
                        hookData: Constants.ZERO_BYTES
                    })
                );
                swapOutput.amountOut = uint256(swapParams.amountSpecified);
                    
            }
            
            delta = toBalanceDelta(
                zeroForOne ? swapParams.amountSpecified.toInt128() : int256(swapOutput.amountOut).toInt128(),
                zeroForOne ? -int256(swapOutput.amountOut).toInt128() : swapParams.amountSpecified.toInt128()
            );
        
    }


    function simulatePriceImpact(
        PoolKey memory poolKey,
        uint160 initialSqrtPriceX96,
        uint128 liquidity,
        SwapParams memory swapParams,
        SwapOutput memory swapOutput
    ) external view returns(uint160,int24){
        (uint160 afterSwapPrice, int24 afterSwapTick) = _simulatePriceImpact(poolKey, initialSqrtPriceX96, liquidity, swapParams, swapOutput);
        return (afterSwapPrice, afterSwapTick);
    }

    function _simulatePriceImpact(
        PoolKey memory poolKey,
        uint160 initialSqrtPriceX96,
        uint128 liquidity,
        SwapParams memory swapParams,
        SwapOutput memory swapOutput
    ) internal virtual view returns(uint160,int24){

        bool isExactInput = swapParams.amountSpecified <0;
        bool zeroForOne = swapParams.zeroForOne;
                   
        uint160 expectedAfterSwapSqrtPriceX96 = isExactInput ? initialSqrtPriceX96.getNextSqrtPriceFromOutput(
            liquidity,
            swapOutput.amountOut,
            zeroForOne
        ) : initialSqrtPriceX96.getNextSqrtPriceFromInput(
            liquidity,
            swapOutput.amountIn,
            zeroForOne
        );
  
        // NOTE: The tick of such after price nees to be rounded to the nearest tick
        // based on the tickSpacing of the pool
        int24 expectedAfterSwapTick = (expectedAfterSwapSqrtPriceX96.getTickAtSqrtPrice().compress(poolKey.tickSpacing))*int24(poolKey.tickSpacing);

        return (expectedAfterSwapSqrtPriceX96, expectedAfterSwapTick);
    }
}