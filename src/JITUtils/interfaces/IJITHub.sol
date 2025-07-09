// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";

import {JITLiquidityDistributionOnSwap, JITLiquidityDistributionOnSwapLibrary} from "../types/JITLiquidityDistributionOnSwap.sol";
//NOTE:
// - JITHUbs set ToxicityLevelCalculator to determine their
//  perceived toxicity level
//

interface IJITHub {
    function calculateJITLiquidityParamsForSwap(
        SwapParams memory swapParams
    )
        external
        returns (
            JITLiquidityDistributionOnSwap memory jitLiquidityDistributionOnSwap
        );
}
