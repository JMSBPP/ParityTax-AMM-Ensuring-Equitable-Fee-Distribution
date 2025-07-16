# ParityTax Hook-AMM (PT-AMM)

## Purpose

To optimize liquidity fulfillment in UniswapV4 by dynamically balancing JIT and PLP incentives through a fee-redistribution system, while managing time-bound LP positions and tax redistribution.

## Responsibilities

*   **JIT Liquidity Taxation:** To enforce a tax on JIT-provided liquidity fees during swap execution (via beforeSwap/afterSwap hooks), based on position duration and market impact.
*   **PLP Reward Redistribution:** To redistribute taxed JIT revenue to PLPs after liquidity removal (via afterRemoveLiquidity hook), weighted by their contribution depth and longevity.
*   **Time-Locked Liquidity Manager:** To track and enforce LP-specified deadlines for JIT liquidity provision, ensuring temporary positions are automatically expired.
*   **Dynamic Incentive Calibration:** To adjust tax rates and redistribution weights in real-time, ensuring PLPs are fairly compensated without disincentivizing JITs for large/non-informed trades.

## Exclusions

*   Core swap execution (handled by PoolManager)
*   Price oracle mechanics
*   LP token minting/burning (handled by PoolManager)