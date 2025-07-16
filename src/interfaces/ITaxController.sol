// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/base/ImmutableState.sol";
import "./ILiquidityTimeCommitmentManager.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "v4-core/types/BalanceDelta.sol";

/// @title ITaxController
/// @author j-money-11
/// @notice Interface for the TaxController contract.
/// @dev This interface defines the external functions for managing fee collection from JIT providers
/// and distribution to PLPs.
interface ITaxController {
    /// @dev Reverts if an action is attempted by a non-PLP.
    error InvalidTimeCommitment___ActionOnlyAvailableToPLP();
    /// @dev Reverts if an action is attempted by a non-JIT.
    error InvalidTimeCommitment___ActionOnlyAvailableToJIT();
    /// @dev Reverts if a PLP tries to withdraw before their commitment has expired.
    error InvalidTimeCommitment___PositionIsNotWithdrawableYet();

    /// @notice Emitted when tax revenue is collected from a JIT provider.
    /// @param poolId The ID of the pool.
    /// @param positionKeyTaxee The key of the JIT position being taxed.
    /// @param feeDeltaAmount0 The amount of token0 collected.
    /// @param feeDeltaAmount1 The amount of token1 collected.
    event TaxRevenueCollected(
        PoolId indexed poolId,
        bytes32 indexed positionKeyTaxee,
        uint128 feeDeltaAmount0,
        uint128 feeDeltaAmount1
    );

    /// @notice Emitted when tax revenue is distributed to a PLP.
    /// @param poolId The ID of the pool.
    /// @param positionKeyReceiver The key of the PLP position receiving the revenue.
    /// @param feeDeltaAmount0 The amount of token0 distributed.
    /// @param feeDeltaAmount1 The amount of token1 distributed.
    event TaxRevenueDistributed(
        PoolId indexed poolId,
        bytes32 indexed positionKeyReceiver,
        uint128 feeDeltaAmount0,
        uint128 feeDeltaAmount1
    );

    /// @notice Collects fee revenue from a JIT provider.
    /// @param key The key of the pool.
    /// @param positionKey The key of the JIT position.
    /// @param feeDelta The fee delta to collect.
    function collectFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey,
        BalanceDelta feeDelta
    ) external;

    /// @notice Distributes collected fee revenue to a PLP.
    /// @param key The key of the pool.
    /// @param positionKey The key of the PLP position.
    /// @return withheldFees The amount of fees distributed.
    function distributeFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey
    ) external returns (BalanceDelta withheldFees);

    /// @notice Updates the tax account for a position.
    /// @dev This is typically called when a position is modified, to update its time commitment.
    /// @param positionKey The key of the position.
    /// @param poolKey The key of the pool.
    /// @param feeDelta The fee delta associated with the update.
    /// @param enteredTimeCommitment The new time commitment.
    function updateTaxAccount(
        bytes32 positionKey,
        PoolKey memory poolKey,
        BalanceDelta feeDelta,
        TimeCommitment enteredTimeCommitment
    ) external;
}