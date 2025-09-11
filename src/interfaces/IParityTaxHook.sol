//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "../types/SwapIntent.sol";

interface IParityTaxHook{


    event PriceImpact(
        bytes32 indexed poolId,
        uint48 indexed blockNumber,
        SwapIntent indexed swapIntent,
        BalanceDelta swapDelta,
        uint160 beforeSwapSqrtPriceX96,
        uint160 beforeSwapExternalSqrtPriceX96,
        uint160 afterSwapSqrtPriceX96,
        uint160 afterSwapExternalSqrtPriceX96
    );

    error AmountOutGreaterThanSwapAmountOut();
    error NotEnoughLiquidity(PoolId poolId);
    error NotWithdrawableLiquidity__LiquidityIsCommitted(uint48 remainingCommitedBlocks);
    error NoLiquidityToReceiveTaxRevenue();
    error CurrencyMissmatch();
    error NoLiquidityToReceiveTaxCredit();
    error InvalidLiquidityRouterCaller();

}