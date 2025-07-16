# JITHub

The `JITHub` contract is a key component of the ParityTax system, responsible for managing and calculating parameters for Just-In-Time (JIT) liquidity provision in Uniswap V4 pools.

## Core Functionalities

- **JIT Liquidity Calculation:** The primary function of the `JITHub` is to determine the optimal parameters for providing JIT liquidity for a given swap. This is achieved through the `calculateJITLiquidityParamsForSwap` function, which analyzes the potential price impact and fees of a swap to decide if JIT liquidity would be profitable. It does this by simulating the swap using the `SwapSimulation` library.

- **Swap Data Tracking:** The contract keeps track of swap data for each pool, which can be used for analysis and to inform future JIT liquidity decisions.

## Key Data Structures

- **`JITLiquidityResult`**: A struct that encapsulates the results of the JIT liquidity calculation, including whether the opportunity is profitable, the calculated swap delta, the required liquidity parameters, the price impact, and the swap fee.

- **`SwapData`**: A struct that stores an array of `SwapParams` for a given pool, providing a history of swaps.

## How It Works

When a swap is initiated in a pool with the `ParityTaxHook`, the hook calls the `JITHub`'s `calculateJITLiquidityParamsForSwap` function. This function simulates the swap to determine the price impact and potential fee revenue. Based on this simulation, it calculates the optimal amount of liquidity to be provided in a tight range around the current price, and returns this information to the hook. The hook then uses these parameters to add the JIT liquidity to the pool just before the swap occurs, and removes it immediately after.
