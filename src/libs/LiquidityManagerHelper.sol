// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import "v4-core/types/BalanceDelta.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "v4-core/libraries/TransientStateLibrary.sol";

import "v4-core/types/Currency.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

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
    /**
     * @notice Calculates the position liquidity delta for a given pool and liquidity parameters.
     * @param poolManager The pool manager interface.
     * @param poolKey The key of the pool containing specific parameters.
     * @param liquidityParams The parameters defining the liquidity modification.
     * @return liquidityDelta The balance delta representing the liquidity change.
     */
    function getPositionLiquidityDelta(
        IPoolManager poolManager,
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams
    ) internal view returns (BalanceDelta liquidityDelta) {
        (uint160 currentSqrtPriceX96, , , ) = poolManager.getSlot0(
            poolKey.toId()
        );

        liquidityDelta = toBalanceDelta(
            SqrtPriceMath
                .getAmount0Delta(
                    currentSqrtPriceX96,
                    liquidityParams.tickLower.getSqrtPriceAtTick(),
                    liquidityParams.liquidityDelta.toInt128().toUint128(),
                    true
                )
                .toInt128(),
            SqrtPriceMath
                .getAmount1Delta(
                    currentSqrtPriceX96,
                    liquidityParams.tickUpper.getSqrtPriceAtTick(),
                    liquidityParams.liquidityDelta.toInt128().toUint128(),
                    true
                )
                .toInt128()
        );
    }

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
        address liquidityProvider,
        address liquidityRouter
    )
        internal
        view
        returns (uint256 userBalance, uint256 poolBalance, int256 delta)
    {
        userBalance = poolKey.currency0.balanceOf(liquidityProvider);
        poolBalance = poolKey.currency0.balanceOf(address(poolManager));
        delta = poolManager.currencyDelta(liquidityRouter, poolKey.currency0);
    }
    function fetchBalancesCurrency1(
        IPoolManager poolManager,
        PoolKey memory poolKey,
        address liquidityProvider,
        address liquidityRouter
    )
        internal
        view
        returns (uint256 userBalance, uint256 poolBalance, int256 delta)
    {
        userBalance = poolKey.currency1.balanceOf(liquidityProvider);
        poolBalance = poolKey.currency1.balanceOf(address(poolManager));
        delta = poolManager.currencyDelta(liquidityRouter, poolKey.currency1);
    }
}
