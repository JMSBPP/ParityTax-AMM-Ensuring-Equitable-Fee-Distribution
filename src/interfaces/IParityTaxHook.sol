//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";

interface IParityTaxHook{
    error AmountOutGreaterThanSwapAmountOut();
    error NotEnoughLiquidity(PoolId poolId);
    error NotWithdrawableLiquidity__LiquidityIsCommitted(uint256 remainingCommitedBlocks);
    error NoLiquidityToReceiveTaxRevenue();
    error CurrencyMissmatch();

}