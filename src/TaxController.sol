// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ITaxController.sol";

/// @title TaxController
/// @author j-money-11
/// @notice This contract manages the collection of fees from JIT providers and the distribution
/// of that revenue to PLPs.
/// @dev It uses the `LiquidityTimeCommitmentManager` to differentiate between JIT and PLP positions
/// and enforce the corresponding rules.
contract TaxController is ITaxController, ImmutableState {
    using CurrencySettler for Currency;

    /// @dev A reference to the LiquidityTimeCommitmentManager.
    ILiquidityTimeCommitmentManager private liquidityTimeCommitmentManager;

    /// @dev Mapping to store fees withheld from JIT providers.
    mapping(PoolId => mapping(bytes32 => BalanceDelta)) private _withheldFees;

    /// @dev Modifier to restrict a function to be called only by PLPs.
    modifier onlyPLP(PoolId poolId, bytes32 positionKey) {
        if (
            !PLP(
                liquidityTimeCommitmentManager.getTimeCommitment(
                    poolId,
                    positionKey
                )
            )
        ) {
            revert InvalidTimeCommitment___ActionOnlyAvailableToPLP();
        }
        _;
    }

    /// @dev Modifier to restrict a function to be called only by PLPs whose time commitment has expired.
    modifier onlyPLPExpired(PoolId poolId, bytes32 positionKey) {
        if (
            !PLP_EXPIRED(
                liquidityTimeCommitmentManager.getTimeCommitment(
                    poolId,
                    positionKey
                )
            )
        ) {
            revert InvalidTimeCommitment___PositionIsNotWithdrawableYet();
        }
        _;
    }

    /// @dev Modifier to restrict a function to be called only by JIT providers.
    modifier onlyJIT(PoolId poolId, bytes32 positionKey) {
        if (
            !JIT(
                liquidityTimeCommitmentManager.getTimeCommitment(
                    poolId,
                    positionKey
                )
            )
        ) {
            revert InvalidTimeCommitment___ActionOnlyAvailableToJIT();
        }
        _;
    }

    constructor(
        IPoolManager _manager,
        ILiquidityTimeCommitmentManager _liquidityTimeCommitmentManager
    ) ImmutableState(_manager) {
        liquidityTimeCommitmentManager = _liquidityTimeCommitmentManager;
    }

    /// @inheritdoc ITaxController
    function collectFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey,
        BalanceDelta feeDelta
    ) external virtual override onlyJIT(key.toId(), positionKey) {
        PoolId poolId = key.toId();

        _withheldFees[poolId][positionKey] =
            _withheldFees[poolId][positionKey] +
            feeDelta;

        key.currency0.take(
            poolManager,
            address(this),
            uint256(uint128(feeDelta.amount0())),
            true
        );
        key.currency1.take(
            poolManager,
            address(this),
            uint256(uint128(feeDelta.amount1())),
            true
        );

        emit TaxRevenueCollected(
            poolId,
            positionKey,
            uint128(feeDelta.amount0()),
            uint128(feeDelta.amount1())
        );
    }

    /// @inheritdoc ITaxController
    function distributeFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey
    )
        external
        virtual
        override
        onlyPLPExpired(key.toId(), positionKey)
        returns (BalanceDelta withheldFees)
    {
        PoolId poolId = key.toId();
        withheldFees = _getFeeRevenueCollected(poolId, positionKey);

        _withheldFees[poolId][positionKey] = BalanceDeltaLibrary.ZERO_DELTA;

        if (withheldFees.amount0() > 0) {
            key.currency0.settle(
                poolManager,
                address(this),
                uint256(uint128(withheldFees.amount0())),
                true
            );
        }
        if (withheldFees.amount1() > 0) {
            key.currency1.settle(
                poolManager,
                address(this),
                uint256(uint128(withheldFees.amount1())),
                true
            );
        }
        emit TaxRevenueDistributed(
            poolId,
            positionKey,
            uint128(withheldFees.amount0()),
            uint128(withheldFees.amount1())
        );
    }

    /// @notice Retrieves the fee revenue collected for a specific position.
    /// @param poolId The ID of the pool.
    /// @param positionKey The key of the position.
    /// @return BalanceDelta The collected fee revenue.
    function _getFeeRevenueCollected(
        PoolId poolId,
        bytes32 positionKey
    ) internal view returns (BalanceDelta) {
        return _withheldFees[poolId][positionKey];
    }

    /// @inheritdoc ITaxController
    function updateTaxAccount(
        bytes32 positionKey,
        PoolKey memory poolKey,
        BalanceDelta feeDelta,
        TimeCommitment enteredTimeCommitment
    ) external override {
        liquidityTimeCommitmentManager.updatePositionTimeCommitment(
            positionKey,
            poolKey,
            enteredTimeCommitment
        );
    }
}