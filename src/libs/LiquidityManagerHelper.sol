// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import "v4-core/types/BalanceDelta.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import "v4-core/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "v4-core/libraries/TransientStateLibrary.sol";

import "v4-core/types/Currency.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/Slot0.sol";
import "v4-core/libraries/Pool.sol";
/// @title Liquidity Manager Helper Library
/// @notice Provides utility functions for managing liquidity in a pool
/// @dev Utilizes various mathematical and state libraries to calculate liquidity deltas
library LiquidityManagerHelper {
    using SafeCast for *;
    using TickMath for int24;
    using StateLibrary for IPoolManager;
    using SqrtPriceMath for uint160;
    using CurrencyLibrary for Currency;
    using TransientStateLibrary for IPoolManager;
    using Slot0Library for *;

    function invariantModifyingLiquidity(
        IPoolManager poolManager,
        PoolKey memory poolKey,
        address liquidityProvider,
        address liquidityRouter,
        uint128 liquidityBefore,
        ModifyLiquidityParams memory liquidityParams,
        uint128 liquidityAfter
    ) internal view returns (bool invariantHolds) {
        bool invariantHolds1 = liquidityBefore.toInt128() +
            liquidityParams.liquidityDelta.toInt128() ==
            liquidityAfter.toInt128();
        (, , int256 delta0) = fetchBalancesCurrency0(
            poolManager,
            poolKey,
            liquidityProvider,
            liquidityRouter
        );
        (, , int256 delta1) = fetchBalancesCurrency1(
            poolManager,
            poolKey,
            liquidityProvider,
            liquidityRouter
        );
        bool invariantHolds2 = (liquidityParams.liquidityDelta < 0)
            ? (delta0 < 0 || delta1 < 0) && !(delta0 > 0 || delta1 > 0)
            : (delta0 > 0 || delta1 > 0) && !(delta0 < 0 || delta1 < 0);
        invariantHolds = invariantHolds1 && invariantHolds2;
    }
    function fetchBalancesCurrency0(
        IPoolManager poolManager,
        PoolKey memory poolKey,
        address user,
        address deltaHolder
    )
        internal
        view
        returns (uint256 userBalance, uint256 poolBalance, int256 delta)
    {
        userBalance = poolKey.currency0.balanceOf(user);
        poolBalance = poolKey.currency0.balanceOf(address(poolManager));
        delta = poolManager.currencyDelta(deltaHolder, poolKey.currency0);
    }
    function fetchBalancesCurrency1(
        IPoolManager poolManager,
        PoolKey memory poolKey,
        address user,
        address deltaHolder
    )
        internal
        view
        returns (uint256 userBalance, uint256 poolBalance, int256 delta)
    {
        userBalance = poolKey.currency1.balanceOf(user);
        poolBalance = poolKey.currency1.balanceOf(address(poolManager));
        delta = poolManager.currencyDelta(deltaHolder, poolKey.currency1);
    }
}
