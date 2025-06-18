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

/// @title Liquidity Manager Helper Library
/// @notice Provides utility functions for managing liquidity in a pool
/// @dev Utilizes various mathematical and state libraries to calculate liquidity deltas
library LiquidityManagerHelper {
    using SafeCast for *;
    using TickMath for int24;
    using StateLibrary for IPoolManager;
    using SqrtPriceMath for uint160;

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
}
