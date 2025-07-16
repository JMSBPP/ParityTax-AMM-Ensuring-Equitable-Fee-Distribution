# ParityTaxHook

The `ParityTaxHook` is a smart contract that acts as a hook for Uniswap V4 pools. It is the central coordinator of the ParityTax system, designed to manage liquidity provision from different sources, distinguishing between Just-In-Time (JIT) liquidity and Provisioned Liquidity Providers (PLPs).

## Key Functionalities

- **Liquidity Management:** The hook intercepts liquidity-related actions (`addLiquidity`, `removeLiquidity`, `swap`) and delegates them to the appropriate components of the ParityTax system.
- **Time-Based Commitments:** The hook uses the `TimeCommitment` mechanism to differentiate between JIT and PLP liquidity. It passes this information to the `TaxController` to manage positions accordingly.
- **Taxation and Revenue Distribution:** The hook interacts with the `TaxController` to collect taxes from JIT providers and enable the distribution of revenue to PLPs.
- **JIT Liquidity Handling:** For swaps, the hook communicates with the `JITHub` to determine the optimal liquidity parameters for a given swap, and then adds and removes the JIT liquidity around the swap.

## Core Components

- **`taxController`**: An instance of the `ITaxController` interface, responsible for managing tax collection and distribution.
- **`jitHub`**: An instance of the `IJITHub` interface, which provides functionalities for JIT liquidity management.

## Hook Permissions

The `ParityTaxHook` implements the following hooks:

- `afterAddLiquidity`: To update time commitments and collect taxes from JIT providers.
- `beforeRemoveLiquidity`: To prevent PLPs from withdrawing liquidity before their commitment expires.
- `afterRemoveLiquidity`: To manage tax income and distribution.
- `beforeSwap`: To handle JIT liquidity provision requests by calling the `JITHub`.
- `afterSwap`: To remove JIT liquidity after the swap is complete.
- `afterSwapReturnDelta`: To enable dynamic fees and taxing.
- `afterAddLiquidityReturnDelta`: To adjust balances after adding liquidity.
- `afterRemoveLiquidityReturnDelta`: To manage revenue from the `TaxController`.