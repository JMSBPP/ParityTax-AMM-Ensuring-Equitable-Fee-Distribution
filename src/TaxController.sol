// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// NOTE This contract needs to have two references one for collecting the taxes on feeDeltas for JIT's
// and other for distributing ree revenue to PLP's

import "./interfaces/ITaxController.sol";

contract TaxController is ITaxController, ImmutableState {
    using CurrencySettler for Currency;
    // NOTE: The contract has a reference to the LiquidityTimeCommitmentManager
    // that tells it the timeCommitment of the position per pool
    ILiquidityTimeCommitmentManager private liquidityTimeCommitmentManager;

    mapping(PoolId => mapping(bytes32 => BalanceDelta)) private _withheldFees;

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

    function collectFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey,
        BalanceDelta feeDelta
    ) external virtual onlyJIT(key.toId(), positionKey) {
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

    function distributeFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey
    )
        external
        virtual
        onlyPLPExpired(key.toId(), positionKey)
        returns (BalanceDelta withheldFees)
    {
        PoolId poolId = key.toId();
        // NOTE: This collects the fee revenue associated with the PLP. In practice
        // we have to aggregat the fee revenue and distribute the corresponding portion to the PLP
        // maiking hte withdrawal request.

        // Therefore this is only for tsting purposes
        withheldFees = _getFeeRevenueCollected(poolId, positionKey);

        // NOTE: This is also for testing pruposes, see above note
        _withheldFees[poolId][positionKey] = BalanceDeltaLibrary.ZERO_DELTA;

        // Settle the `withheldFees` for the liquidity position.
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

    function _getFeeRevenueCollected(
        PoolId poolId,
        bytes32 positionKey
    ) internal view returns (BalanceDelta) {
        return _withheldFees[poolId][positionKey];
    }

    function updateTaxAccount(
        bytes32 positionKey,
        PoolKey memory poolKey,
        BalanceDelta feeDelta,
        TimeCommitment enteredTimeCommitment
    ) external {
        
        {
            liquidityTimeCommitmentManager.updatePositionTimeCommitment(
                positionKey,
                poolKey,
                enteredTimeCommitment
            );
        }
    }
}
