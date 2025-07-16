# TimeCommitment

The `TimeCommitment` type is a custom data type defined as a `uint96` value. It is designed to efficiently store two pieces of information for a liquidity position: the time the commitment was made and the duration of the commitment. This allows the system to distinguish between Provisioned Liquidity Providers (PLPs) and Just-In-Time (JIT) providers and to enforce time-based rules.

## Data Structure

The `uint96` value is split into two `uint48` parts:

- **Bits 95-48 (Most Significant 48 bits):** Store the `block.timestamp` of when the commitment was recorded.
- **Bits 47-0 (Least Significant 48 bits):** Store the commitment value itself, which typically represents a future timestamp until which the liquidity is committed.

Special values are reserved for JIT and uninitialized states.

## States

A `TimeCommitment` can represent several states:

- **`PLP` (Provisioned Liquidity Provider):** A standard time-locked position. The commitment value is a timestamp in the future.
- **`JIT` (Just-In-Time):** A non-time-locked position, identified by a special flag (`type(uint48).max`). These positions are flexible and not subject to withdrawal deadlines.
- **`UNINITIALIZED`:** The default zero state for a position with no commitment.
- **`PLP_EXPIRED`:** A PLP position whose commitment timestamp is in the past, making it eligible for withdrawal.
- **`PLP_NOT_EXPIRED`:** An active PLP position that is still within its commitment period.

## Key Functions

- **`PLP(TimeCommitment)`:** Returns `true` if the time commitment represents a Provisioned Liquidity Provider (PLP).
- **`JIT(TimeCommitment)`:** Returns `true` if the time commitment represents a Just-In-Time (JIT) liquidity provider.
- **`UNINITIALIZED(TimeCommitment)`:** Returns `true` if the time commitment is uninitialized.
- **`PLP_EXPIRED(TimeCommitment)`:** Returns `true` if the commitment is for a PLP and the commitment has expired.
- **`PLP_NOT_EXPIRED(TimeCommitment)`:** Returns `true` if the commitment is for a PLP and the commitment has not expired.
- **`timeStamp(TimeCommitment)`:** Returns the block timestamp of when the time commitment was made.
- **`timeCommitmentValue(TimeCommitment)`:** Returns the duration/end-timestamp of the time commitment.
- **`toTimeCommitment(uint48)`:** Creates a new `TimeCommitment` from a given duration, using the current `block.timestamp`.
- **`add(TimeCommitment, TimeCommitment)`:** Defines the logic for combining two commitments, handling transitions between states (e.g., JIT to PLP) and extensions of existing commitments.