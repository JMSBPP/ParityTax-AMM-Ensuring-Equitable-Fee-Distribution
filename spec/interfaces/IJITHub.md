# IJITHub

This interface defines the external functions of the `JITHub` contract. It provides a standard way for other contracts, primarily the `ParityTaxHook`, to request JIT liquidity calculations.

## `JITLiquidityResult` Struct

This struct encapsulates the results of the JIT liquidity calculation.

- **`isProfitable`**: A boolean indicating whether providing JIT liquidity for the swap is likely to be profitable.
- **`swapDelta`**: The predicted change in balances from the swap.
- **`jitLiquidityParams`**: The recommended `ModifyLiquidityParams` for the JIT provider to use.
- **`priceImpact`**: The predicted price impact of the swap.
- **`swapFee`**: The fee earned from the swap.

## Functions

- **`calculateJITLiquidityParamsForSwap(address routerSender, PoolKey memory poolKey, SwapParams memory swapParams)`**: This is the core function of the `JITHub`. It takes the details of a potential swap and returns a `JITLiquidityResult` struct with the optimal parameters for providing JIT liquidity.
