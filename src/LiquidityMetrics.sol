// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LiquidityMetrics
 * @author ParityTax Team
 * @notice Contract for calculating liquidity metrics for PLP and JIT providers
 * @dev Provides functions to calculate available liquidity for swaps across different tick ranges
 * and liquidity provider types (PLP and JIT)
 */

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
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";

import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";
import {SwapIntent,SwapIntentLibrary} from "./types/SwapIntent.sol";


import "./types/Shared.sol";
import "./interfaces/ILiquidityMetrics.sol";

//TODO: This is better as a library 
contract LiquidityMetrics is ILiquidityMetrics {
    using SwapIntentLibrary for bool;
    using LiquidityAmounts for uint160;
    using SqrtPriceMath for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    /// @notice The pool manager contract for accessing pool state
    IPoolManager manager;
    
    /**
     * @notice Initializes the LiquidityMetrics contract
     * @dev Sets up the pool manager for liquidity calculations
     * @param _poolManager The Uniswap V4 pool manager contract
     */
    constructor(
        IPoolManager _poolManager
    ) {
        manager = _poolManager;
    }

    /**
     * @inheritdoc ILiquidityMetrics
     */
    function getSwapPLPLiquidity(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper 
    ) external view returns(uint128){
        uint128 swapPLPLiquidity = _getSwapPLPLiquidity( poolKey,_tickLower,_tickUpper);
        return swapPLPLiquidity;
    }

    /**
     * @notice Internal function to calculate PLP liquidity across a tick range
     * @dev Iterates through ticks in the specified range and aggregates liquidity
     * @param poolKey Pool configuration data including currencies and fee tier
     * @param _tickLower The lower tick boundary for the liquidity calculation
     * @param _tickUpper The upper tick boundary for the liquidity calculation
     * @return The total PLP liquidity available in the specified tick range
     * @dev Make sure ticks are in order before processing
     */
    function _getSwapPLPLiquidity(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper 
    ) internal virtual view returns(uint128){
        (int24 tickLower, int24 tickUpper) = _tickUpper < _tickLower ? (
            _tickUpper,
            _tickLower
        ) : (_tickLower, _tickUpper);

        PoolId poolId = poolKey.toId();

        uint24 tickRangeLength = uint24((tickUpper - tickLower) / poolKey.tickSpacing);

        int24 currentTick = tickLower;
        int128 totalLiquidity;

        while (currentTick <= tickUpper){
            (uint128 currentTickLiquidity,int128 currentTickLiquidityDelta) = manager.getTickLiquidity(
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
    /**
     * @inheritdoc ILiquidityMetrics
     */
    function getSwapJITLiquidity(
        PoolKey memory poolKey,
        SwapParams memory swapParams,
        int24 _tickLower,
        int24 _tickUpper
    ) external  returns(uint128){
        uint128 swapJITLiquidity = _getSwapJITLiquidity(poolKey, swapParams, _tickLower, _tickUpper);
        return swapJITLiquidity;
    }

    /**
     * @notice Internal function to calculate JIT liquidity for a swap
     * @dev Calculates the liquidity required for a JIT provider to fulfill a swap
     * @param poolKey Pool configuration data including currencies and fee tier
     * @param swapParams Swap parameters including amount and direction
     * @param _tickLower The lower tick boundary for the liquidity calculation
     * @param _tickUpper The upper tick boundary for the liquidity calculation
     * @return The JIT liquidity required for the specified swap
     * @dev WARNING: This function logic is incorrect and needs to be fixed
     */
    function _getSwapJITLiquidity(
        PoolKey memory poolKey,
        SwapParams memory swapParams,
        int24 _tickLower,
        int24 _tickUpper
    ) internal virtual returns(uint128){

        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,,,) = manager.getSlot0(poolId);
        uint160 sqrtRatioTickLower = _tickLower.getSqrtPriceAtTick();
        uint160 sqrtRatioTickUpper = _tickUpper.getSqrtPriceAtTick();
        SwapIntent swapIntent = swapParams.zeroForOne.swapIntent(swapParams.amountSpecified <0);
        uint128 swapJITLiquidity = sqrtPriceX96.getLiquidityForAmounts(
            sqrtRatioTickLower,
            sqrtRatioTickUpper,
            swapIntent == SwapIntent.EXACT_INPUT_ZERO_FOR_ONE 
            || swapIntent == SwapIntent.EXACT_OUTPUT_ONE_FOR_ZERO
             ? uint256(swapParams.amountSpecified)
             : uint256(0x00),
            swapIntent == SwapIntent.EXACT_INPUT_ONE_FOR_ZERO
            || swapIntent == SwapIntent.EXACT_OUTPUT_ZERO_FOR_ONE
            ? uint256(swapParams.amountSpecified)
            : uint256(0x00)
        );
        return swapJITLiquidity;

    }




}