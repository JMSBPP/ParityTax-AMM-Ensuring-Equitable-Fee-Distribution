# ITaxController

This interface defines the external functions of the `TaxController` contract. It provides a standard way for other contracts, like the `ParityTaxHook`, to interact with the fee collection and distribution logic.

## Functions

- **`collectFeeRevenue(PoolKey calldata key, bytes32 positionKey, BalanceDelta feeDelta)`**: Called to collect fees from JIT providers.
- **`distributeFeeRevenue(PoolKey calldata key, bytes32 positionKey)`**: Called by PLPs to claim their share of collected fee revenue.
- **`updateTaxAccount(bytes32 positionKey, PoolKey memory poolKey, BalanceDelta feeDelta, TimeCommitment enteredTimeCommitment)`**: Updates the time commitment of a position.

## Events

- **`TaxRevenueCollected(PoolId indexed poolId, bytes32 indexed positionKeyTaxee, uint128 feeDeltaAmount0, uint128 feeDeltaAmount1)`**: Emitted when fees are collected from a JIT provider.
- **`TaxRevenueDistributed(PoolId indexed poolId, bytes32 indexed positionKeyReceiver, uint128 feeDeltaAmount0, uint128 feeDeltaAmount1)`**: Emitted when fee revenue is distributed to a PLP.

## Errors

- **`InvalidTimeCommitment___ActionOnlyAvailableToPLP()`**: Reverts if a function restricted to PLPs is called by a non-PLP.
- **`InvalidTimeCommitment___ActionOnlyAvailableToJIT()`**: Reverts if a function restricted to JITs is called by a non-JIT.
- **`InvalidTimeCommitment___PositionIsNotWithdrawableYet()`**: Reverts if a PLP attempts to withdraw rewards before their time commitment has expired.
