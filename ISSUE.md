# Underflow Error in test__Unit_JITSingleLP Test

## Issue Description

When running `forge test --mt test__Unit_JITSingleLP`, the test fails with an arithmetic underflow error during the `transferFrom` operation in the MockJITHub contract.

## Environment

- **Repository**: ParityTax-AMM-Ensuring-Equitable-Fee-Distribution
- **Branch**: atrium-cohort5-deliverable
- **Solidity Version**: 0.8.26
- **Foundry**: Latest version

## Error Details

The error occurs in the following trace:
```
[5290] 0x000000000022D473030F116dDEE9F6B43aC78BA3::transferFrom(MockJITHub: [0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240], PoolManager: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 994024895398478 [9.94e14], currency1: [0x2a07706473244bc757e10f2a9e86fb532828afe3])
    ├─ [3855] currency1::transferFrom(MockJITHub: [0xDB25A7b768311dE128BBDa7B8426c3f9C74f3240], PoolManager: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 994024895398478 [9.94e14])
    │   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
    └─ ← [Revert] TRANSFER_FROM_FAILED
```

## Steps to Reproduce

1. Clone the repository: `git clone https://github.com/JMSBPP/ParityTax-AMM-Ensuring-Equitable-Fee-Distribution.git`
2. Checkout the branch: `git checkout atrium-cohort5-deliverable`
3. Install dependencies: `forge install`
4. Run the specific test: `forge test --mt test__Unit_JITSingleLP`

## Expected Behavior

The test should pass successfully, simulating a swap operation where JIT liquidity is provided to fulfill part of a trade.

## Actual Behavior

The test fails with an arithmetic underflow error when the MockJITHub attempts to transfer tokens back to the PoolManager.

## Project Context

This project aims to create a unified system where JIT (Just-In-Time) and PLP (Passive Liquidity Provider) liquidity can coexist under fair conditions, allowing governance to plug different tax schemas for maximizing AMM welfare.

The failing test is part of the core functionality that ensures JIT liquidity providers can properly participate in swap operations before the swap is executed.

## Additional Information

- The error occurs during the `fillSwap` function in `MockJITHub.sol`
- The JITHub has sufficient token balance as shown in the logs
- The issue appears to be related to the token flow between the PoolManager and JITHub during swap operations
- This is blocking progress on implementing the core JIT liquidity functionality

## Related Files

- `test/ParityTaxTest.t.sol` - Contains the failing test
- `test/mocks/MockJITHub.sol` - Contains the MockJITHub implementation where the error occurs
- `src/ParityTaxHook.sol` - The main hook implementation that orchestrates the swap
- `src/ParityTaxRouter.sol` - The router that initiates the swap

## Request for Help

We're looking for assistance in understanding why the token transfer is failing despite the JITHub having sufficient balance. Any insights into the correct token flow pattern for this type of Uniswap V4 hook implementation would be greatly appreciated.