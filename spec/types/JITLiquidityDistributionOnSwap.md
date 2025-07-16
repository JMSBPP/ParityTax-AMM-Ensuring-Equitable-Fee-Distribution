# JITLiquidityDistributionOnSwap

The `JITLiquidityDistributionOnSwap` struct is used to represent the distribution of Just-In-Time (JIT) liquidity for a specific swap.

## Structure

```solidity
struct JITLiquidityDistributionOnSwap {
    SwapParams swapParams;
    ModifyLiquidityParams jitLiquidityParamsOnSwap;
}
```

- **`swapParams`**: The parameters of the swap for which JIT liquidity is being considered.
- **`jitLiquidityParamsOnSwap`**: The parameters for modifying the liquidity, i.e., adding the JIT liquidity to the pool.
