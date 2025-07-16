// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Pool} from "v4-core/libraries/Pool.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {JITLiquidityDistributionOnSwap, JITLiquidityDistributionOnSwapLibrary} from "../types/JITLiquidityDistributionOnSwap.sol";

/**
 * @title JITLiquidityResult
 * @author j-money-11
 * @notice A struct to hold the results of a JIT liquidity calculation.
 */
struct JITLiquidityResult {
    bool isProfitable;
    BalanceDelta swapDelta;
    ModifyLiquidityParams jitLiquidityParams;
    uint256 priceImpact;
    uint24 swapFee;
}

/**
 * @title IJITHub
 * @author j-money-11
 * @notice Interface for the JITHub contract.
 * @dev This interface defines the external functions for calculating JIT liquidity parameters.
 */
interface IJITHub {
    /**
     * @notice Calculates the optimal JIT liquidity parameters for a given swap.
     * @param routerSender The address of the router sending the swap.
     * @param poolKey The key of the pool.
     * @param swapParams The parameters of the swap.
     * @return jitLiquidityResult A struct containing the results of the calculation.
     */
    function calculateJITLiquidityParamsForSwap(
        address routerSender,
        PoolKey memory poolKey,
        SwapParams memory swapParams
    ) external view returns (JITLiquidityResult memory jitLiquidityResult);
}