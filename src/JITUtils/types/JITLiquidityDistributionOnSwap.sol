// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PositionConfig} from "v4-periphery/src/libraries/PositionConfig.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "v4-core/libraries/TransientStateLibrary.sol";

import {Position} from "v4-core/libraries/Position.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {LiquidityMath} from "v4-core/libraries/LiquidityMath.sol";
import {LiquidityAmounts} from "v4-periphery/src/libraries/LiquidityAmounts.sol";
import {LiquidityOperations} from "v4-periphery/test/shared/LiquidityOperations.sol";

//NOTE We probably need to import more types here

import {Pool} from "v4-core/libraries/Pool.sol";

//==============BUNNI-IMPORTS ======================
import {ILiquidityDensityFunction} from "bunni-v2/src/interfaces/ILiquidityDensityFunction.sol";
struct JITLiquidityDistributionOnSwap {
    SwapParams swapParams;
    ModifyLiquidityParams jitLiquidityParamsOnSwap;
}

library JITLiquidityDistributionOnSwapLibrary {
    using LiquidityAmounts for uint160;
    using SqrtPriceMath for uint160;
    using TickMath for int24;
    using TickMath for uint160;
    using LPFeeLibrary for uint24;
    using BalanceDeltaLibrary for BalanceDelta;
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    // TODO: This is we are finding
    // [i_l,i_s](SwapParams, PoolState)

    function getPositionTickRange(
        JITLiquidityDistributionOnSwap memory jitLiquidityDistributionOnSwap
    ) internal view returns (PositionConfig memory) {}

    //TODO: a0([i_l,i_s]),a1([i_l,i_s])
    // This integrates with StepComputations
    // amountIn, amountOut
    // This ressembles what was defined on Bunni for
    // Liquidity distributions

    // TODO: Get the swap slippage associated with the
    // swap
}
