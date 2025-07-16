# LiquidityTimeCommitmentManager

The `LiquidityTimeCommitmentManager` contract is responsible for tracking the time commitments of liquidity positions in Uniswap V4 pools. This is a core component of the ParityTax system, as it provides the data needed to differentiate between Provisioned Liquidity Providers (PLPs) and Just-In-Time (JIT) providers.

## Core Functionalities

- **Time Commitment Tracking:** The contract stores a mapping from a position's key to its `TimeCommitment` struct. This struct contains information about the duration of the liquidity provision and when it was made.

- **Update Time Commitments:** The `updatePositionTimeCommitment` function allows for updating the time commitment of a specific liquidity position. This function is called by the `TaxController` when a liquidity provider adds or modifies their position.

- **Retrieve Time Commitments:** The `getTimeCommitment` function allows other contracts to retrieve the time commitment of a specific liquidity position. This is used by the `TaxController` to enforce rules based on the provider type (PLP or JIT).

## Events

- **`PositionTimeCommitmentUpdated`**: This event is emitted whenever the time commitment of a position is updated. It includes the pool ID, the position key, the new time commitment value, and the liquidity of the position.
