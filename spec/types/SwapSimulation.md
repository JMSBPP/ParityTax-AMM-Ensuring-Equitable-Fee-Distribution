# SwapSimulation

The `SwapSimulation` struct and its associated library are used to simulate a swap in a Uniswap V4 pool. This is a critical component for the `JITHub` to predict the outcome of a swap, including price impact and fees, before deciding whether to provide Just-In-Time liquidity.

## `SwapSimulation` Struct

This struct holds the necessary parameters for a swap simulation.

```solidity
struct SwapSimulation {
    IPoolManager manager;
    PoolId poolId;
    Pool.SwapParams swapParams;
}
```

- **`manager`**: The `IPoolManager` instance for the pool.
- **`poolId`**: The ID of the pool where the swap is being simulated.
- **`swapParams`**: The parameters of the swap to be simulated.

## `SwapSimulationLibrary`

This library contains the logic for running the simulation.

### Key Functions

- **`simulateSwapPLPLiquidity(SwapSimulation)`**: This function simulates a swap using the existing passive liquidity in the pool. It calculates the resulting change in balances (`swapDelta`), the fees paid to the protocol, the total swap fee, and other results of the swap. This allows the `JITHub` to analyze the profitability of providing JIT liquidity for the given swap.
