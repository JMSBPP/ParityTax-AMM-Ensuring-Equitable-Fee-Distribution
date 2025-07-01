// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/base/ImmutableState.sol";
import "./ILiquidityTimeCommitmentManager.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "v4-core/types/BalanceDelta.sol";

interface ITaxController {
    error InvalidTimeCommitment___ActionOnlyAvailableToPLP();
    error InvalidTimeCommitment___ActionOnlyAvailableToJIT();
    error InvalidTimeCommitment___PositionIsNotWithdrawableYet();
    event TaxRevenueCollected(
        PoolId indexed poolId,
        bytes32 indexed positionKeyTaxee,
        uint128 feeDeltaAmount0,
        uint128 feeDeltaAmount1
    );

    event TaxRevenueDistributed(
        PoolId indexed poolId,
        bytes32 indexed positionKeyReceiver,
        uint128 feeDeltaAmount0,
        uint128 feeDeltaAmount1
    );

    function collectFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey,
        BalanceDelta feeDelta
    ) external;

    function distributeFeeRevenue(
        PoolKey calldata key,
        bytes32 positionKey
    ) external returns (BalanceDelta withheldFees);

    function updateTaxAccount(
        bytes32 positionKey,
        PoolKey memory poolKey,
        BalanceDelta feeDelta,
        TimeCommitment enteredTimeCommitment
    ) external;
}
