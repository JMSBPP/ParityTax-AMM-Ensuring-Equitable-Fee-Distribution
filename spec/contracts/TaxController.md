# TaxController

The `TaxController` contract is responsible for managing the collection of fees from Just-In-Time (JIT) liquidity providers and the distribution of that revenue to Provisioned Liquidity Providers (PLPs). This is the core of the ParityTax incentive mechanism.

## Core Functionalities

- **Fee Collection:** The `collectFeeRevenue` function is called by the `ParityTaxHook` to collect fees from JIT providers. This function withholds the fee delta from the JIT provider and stores it in the contract.

- **Fee Distribution:** The `distributeFeeRevenue` function allows PLPs whose time commitment has expired to claim their share of the collected fee revenue.

- **Tax Account Management:** The `updateTaxAccount` function is used to update the time commitment of a liquidity position, which is essential for the `TaxController` to correctly identify the provider type.

## Access Control

The `TaxController` uses a set of modifiers to ensure that only the appropriate liquidity providers can access certain functions:

- `onlyPLP`: Restricts a function to be called only by PLPs.
- `onlyPLPExpired`: Restricts a function to be called only by PLPs whose time commitment has expired.
- `onlyJIT`: Restricts a function to be called only by JIT providers.

## Dependencies

- **`ILiquidityTimeCommitmentManager`**: The `TaxController` relies on the `LiquidityTimeCommitmentManager` to determine the time commitment of a liquidity position and thus differentiate between JIT and PLP providers.
