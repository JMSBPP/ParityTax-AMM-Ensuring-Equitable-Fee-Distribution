// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Pool} from "v4-core/libraries/Pool.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {JITLiquidityDistributionOnSwap, JITLiquidityDistributionOnSwapLibrary} from "../types/JITLiquidityDistributionOnSwap.sol";
//NOTE:
// - JITHUbs set ToxicityLevelCalculator to determine their
//  perceived toxicity level
//
struct JITLiquidityResult {
    bool isProfitable;
    BalanceDelta swapDelta;
    ModifyLiquidityParams jitLiquidityParams;
    uint256 priceImpact;
    uint24 swapFee;
}
interface IJITHub {
    function calculateJITLiquidityParamsForSwap(
        address routerSender, // This needs to be passed
        // from the hook to the JITHub
        PoolKey memory poolKey,
        SwapParams memory swapParams
    ) external view returns (JITLiquidityResult memory jitLiquidityResult);
}
