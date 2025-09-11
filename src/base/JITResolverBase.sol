//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IJITResolver.sol";
import "./ResolverBase.sol";

import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/src/libraries/TickBitmap.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {SwapIntent,SwapIntentLibrary} from "../types/SwapIntent.sol";
import {PoolId,PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

abstract contract JITResolverBase is IJITResolver, ResolverBase{
    using SwapIntentLibrary for bool;
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;
    using TickMath for uint160;
    using TickMath for int24;
    using TickBitmap for int24;
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant JIT_Transient_MetricsLocation = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;

    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm
    ) ResolverBase(_poolManager, _lpm){}


    // NOTE: This method is to be overwritten
    // for child contracts
    
    function getSwapJITLiquidity(
        PoolKey memory poolKey,
        SwapParams memory swapParams,
        int24 _tickLower,
        int24 _tickUpper
    ) public virtual returns(uint128){

        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);
        uint160 sqrtRatioTickLower = _tickLower.getSqrtPriceAtTick();
        uint160 sqrtRatioTickUpper = _tickUpper.getSqrtPriceAtTick();
        SwapIntent swapIntent = swapParams.zeroForOne.swapIntent(swapParams.amountSpecified <0);
        
        return sqrtPriceX96.getLiquidityForAmounts(
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

    }


}







