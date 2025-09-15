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


/**
 * @title SwapMetrics
 * @author ParityTax Team
 * @notice Abstract contract for calculating swap metrics and price impact analysis
 * @dev Provides functions to compare swap outputs between hooked and unhooked pools,
 * simulate price impact, and analyze swap performance metrics
 */
abstract contract SwapMetrics is ISwapMetrics{
    using SafeCast for *;
    using SqrtPriceMath for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;

    /// @notice The V4Quoter contract for simulating swap outputs
    IV4Quoter v4Quoter;

    /**
     * @notice Initializes the SwapMetrics contract
     * @dev Sets up the V4Quoter for swap simulation functionality
     * @param _v4Quoter The Uniswap V4 quoter contract for price calculations
     */
    constructor(
        IV4Quoter _v4Quoter
    )
    {
        v4Quoter = _v4Quoter;
         
    }


    /**
     * @inheritdoc ISwapMetrics
     */
    function compareSwapOutput(
        PoolKey memory hookedKey,
        SwapParams memory swapParams,
        PoolKey memory comparedPoolKey
    ) external view returns(BalanceDelta delta){
        delta = _compareSwapOutput(hookedKey, swapParams, comparedPoolKey);
    }


    /**
     * @notice Internal function to compare swap outputs between different pool configurations
     * @dev Virtual function to be implemented by derived contracts for specific comparison logic
     * @param hookedKey The pool key with hooks enabled
     * @param swapParams The swap parameters for the comparison
     * @param comparedPoolKey The pool key to compare against
     * @return delta The balance delta representing the difference in swap outputs
     */
    function _compareSwapOutput(
        PoolKey memory hookedKey,
        SwapParams memory swapParams,
        PoolKey memory comparedPoolKey
    ) internal virtual view returns(BalanceDelta delta){
    }


    /**
     * @inheritdoc ISwapMetrics
     */
    function simulateSwapOutputOnUnHookedPool(
        PoolKey memory hookedKey,
        SwapParams memory swapParams
    ) external returns(BalanceDelta delta, SwapOutput memory swapOutput){
        (delta, swapOutput) = _simulateSwapOutputOnUnHookedPool(hookedKey, swapParams);
    }


    /**
     * @notice Internal function to simulate swap output on an unhooked pool
     * @dev Creates a pool key without hooks and simulates the swap using V4Quoter
     * @param hookedKey The original pool key with hooks
     * @param swapParams The swap parameters for simulation
     * @return delta The balance delta representing the swap impact
     * @return swapOutput The simulated swap output with amount in and out
     */
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


    /**
     * @inheritdoc ISwapMetrics
     */
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

    /**
     * @notice Internal function to simulate price impact of a swap
     * @dev Calculates the expected price and tick after a swap based on liquidity and swap parameters
     * @param poolKey The pool configuration data
     * @param initialSqrtPriceX96 The initial sqrt price before the swap
     * @param liquidity The available liquidity for the swap
     * @param swapParams The swap parameters
     * @param swapOutput The expected swap output amounts
     * @return expectedAfterSwapSqrtPriceX96 The expected sqrt price after the swap
     * @return expectedAfterSwapTick The expected tick after the swap
     * @dev NOTE: The tick of such after price needs to be rounded to the nearest tick
     * based on the tickSpacing of the pool
     */
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