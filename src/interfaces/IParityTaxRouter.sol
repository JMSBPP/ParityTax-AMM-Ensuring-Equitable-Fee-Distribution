// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ISwapMetrics} from  "./ISwapMetrics.sol";
import {ILiquidityMetrics} from "./ILiquidityMetrics.sol";
import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";


interface IParityTaxRouter is ISwapMetrics , ILiquidityMetrics, ISubscriber{
    
    function swap(
        PoolKey memory poolKey,
        SwapParams memory swapParams
    ) external payable returns (BalanceDelta delta);

    function modifyLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        uint48 plpLiquidityBlockCommitment 
    ) external payable returns (BalanceDelta delta);
    

}