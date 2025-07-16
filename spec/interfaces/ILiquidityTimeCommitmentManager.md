# ILiquidityTimeCommitmentManager

This interface defines the external functions of the `LiquidityTimeCommitmentManager` contract. It provides a standard way for other contracts, such as the `TaxController`, to interact with the time commitment data of liquidity positions.

## Functions

- **`updatePositionTimeCommitment(bytes32 positionKey, PoolKey memory poolKey, TimeCommitment enteredTimeCommitment)`**: Updates the time commitment for a given position.
- **`getTimeCommitment(PoolId poolId, bytes32 positionKey)`**: Retrieves the current time commitment for a given position.

## Events

- **`PositionTimeCommitmentUpdated(PoolId indexed poolId, bytes32 indexed positionKey, uint48 indexed timeCommitmentValue, uint128 liquidity)`**: Emitted whenever a position's time commitment is updated.
