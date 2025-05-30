// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import "v4-core/types/PoolOperation.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
/// @title JIT
/// @notice A minimal contract for Just-In-Time (JIT) positions
abstract contract JIT is BaseHook {
    using StateLibrary for IPoolManager;
    // This are artifcts to store the tick range on a
    // specifict transient storage slot
    bytes32 constant TICK_LOWER_SLOT = keccak256("tickLower");
    bytes32 constant TICK_UPPER_SLOT = keccak256("tickUpper");

    constructor(IPoolManager _manager) BaseHook(_manager) {}

    /// @notice Determine the tick range for the JIT position
    /// @param key The pool key
    /// @param params The SwapParams of the current swap. Includes trade size and direction
    /// @param amount0 the currency0 amount to be used on the JIT range
    /// @param amount1 the currency1 amount to be used on the JIT range
    /// @param sqrtPriceX96 The current sqrt price of the pool
    /// @return tickLower The lower tick of the JIT position
    /// @return tickUpper The upper tick of the JIT position
    function _getTickRange(
        PoolKey calldata key,
        SwapParams calldata params,
        uint128 amount0,
        uint128 amount1,
        uint160 sqrtPriceX96
    ) internal view virtual returns (int24 tickLower, int24 tickUpper);

    /// @notice Create a JIT position
    /// @param key The pool key the position will be created on
    /// @param params The SwapParams of the current swap
    /// @param amount0 the currency0 amount to be used on the JIT range
    /// @param amount1 the currency1 amount to be used on the JIT range
    function _createPosition(
        PoolKey calldata key,
        SwapParams calldata params,
        uint128 amount0,
        uint128 amount1,
        bytes calldata hookDataOpen
    )
        internal
        virtual
        returns (
            BalanceDelta delta,
            BalanceDelta feesAccrued,
            uint128 liquidity
        )
    {
        // What is the current sqrt price of the pool?
        (uint160 sqrtPriceX96, , , ) = poolManager.getSlot0(key.toId());
        // What is optimal tick range where I will be depositing liquidity based
        // on the current sqrt price?
        (int24 tickLower, int24 tickUpper) = _getTickRange(
            key,
            params,
            amount0,
            amount1,
            sqrtPriceX96
        );

        // What is the liquidity I will provide on the tick range ?
        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            amount0,
            amount1
        );

        // Where do I store the tick range to close my liquidity
        // once I am done with the JIT position?
        _storeTicks(tickLower, tickUpper);

        // The flow of my transaction
        // Given (L[pl, pu], P) I proceed
        //  --> deposit(L[pl,pu])
        //  --> afterSwpap()
        //  --> withdraw(L[pl,pu])
        (delta, feesAccrued) = _modifyLiquidity(
            key,
            tickLower,
            tickUpper,
            int256(uint256(liquidity)),
            hookDataOpen
        );
    }

    /// @notice Close the JIT position
    /// @param key The pool key the position will be closed on
    /// @param liquidityToClose The amount of liquidity to close
    function _closePosition(
        PoolKey calldata key,
        uint128 liquidityToClose,
        bytes calldata hookDataClose
    ) internal virtual returns (BalanceDelta delta, BalanceDelta feesAccrued) {
        // load the tick range of the JIT position
        (int24 tickLower, int24 tickUpper) = _loadTicks();

        // close the JIT position
        (delta, feesAccrued) = _modifyLiquidity(
            key,
            tickLower,
            tickUpper,
            -int256(uint256(liquidityToClose)),
            hookDataClose
        );
    }

    /// @notice Optionally overridable function for modifying liquidity on the core PoolManager
    /// @param key The pool key the position will be created on
    /// @param tickLower The lower tick of the JIT position
    /// @param tickUpper The upper tick of the JIT position
    /// @param liquidityDelta The amount of liquidity units to add or remove
    function _modifyLiquidity(
        PoolKey memory key,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta,
        bytes calldata hookData
    )
        internal
        virtual
        returns (BalanceDelta totalDelta, BalanceDelta feesAccrued)
    {
        (totalDelta, feesAccrued) = poolManager.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: liquidityDelta,
                salt: bytes32(0)
            }),
            hookData
        );
    }

    /// @dev Store the tick range of the JIT position
    function _storeTicks(int24 tickLower, int24 tickUpper) private {
        bytes32 tickLowerSlot = TICK_LOWER_SLOT;
        bytes32 tickUpperSlot = TICK_UPPER_SLOT;
        assembly {
            tstore(tickLowerSlot, tickLower)
            tstore(tickUpperSlot, tickUpper)
        }
    }

    /// @dev Load the tick range of the JIT position, to be used to close the position
    function _loadTicks()
        private
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        bytes32 tickLowerSlot = TICK_LOWER_SLOT;
        bytes32 tickUpperSlot = TICK_UPPER_SLOT;
        assembly {
            tickLower := tload(tickLowerSlot)
            tickUpper := tload(tickUpperSlot)
        }
    }
}
