# SwapData

The `SwapData` struct is used to store an array of `SwapParams` for a given pool. This provides a history of swaps that can be used for analysis and to inform JIT liquidity decisions.

## Structure

```solidity
struct SwapData {
    SwapParams[] poolSwaps;
}
```

- **`poolSwaps`**: A dynamic array of `SwapParams` structs, where each entry represents a swap that occurred in the pool.
