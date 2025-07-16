// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IParityTaxHook.sol";
import "./base/HookCallableBaseHook.sol";
import "../types/TimeCommitment.sol";

import "v4-core/libraries/Position.sol";
import "v4-core/types/BalanceDelta.sol";
import "v4-core/types/BeforeSwapDelta.sol";
import "v4-periphery/src/base/DeltaResolver.sol";
import "v4-core/libraries/CurrencyReserves.sol";
import {CurrencyLibrary} from "v4-core/types/Currency.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "v4-core/libraries/TransientStateLibrary.sol";
import "v4-core/libraries/StateLibrary.sol";
import {CurrencyDelta} from "v4-core/libraries/CurrencyDelta.sol";
import {NonzeroDeltaCount} from "v4-core/libraries/NonzeroDeltaCount.sol";

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {ITaxController} from "../interfaces/ITaxController.sol";
import {IJITHub, JITLiquidityResult} from "../JITUtils/interfaces/IJITHub.sol";
import {console} from "forge-std/Test.sol";

/**
 * @title ParityTaxHook
 * @author j-money-11
 * @notice This hook manages liquidity provision from different sources (JIT and PLP),
 * and orchestrates the ParityTax system of taxing JIT providers and rewarding PLPs.
 */
contract ParityTaxHook is HookCallableBaseHook, IParityTaxHook {
    using Position for address;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using CurrencyDelta for Currency;
    using BalanceDeltaLibrary for BalanceDelta;
    using SafeCast for *;
    using StateLibrary for IPoolManager;

    /// @dev A reference to the TaxController.
    ITaxController private taxController;
    /// @dev A reference to the JITHub.
    IJITHub private jitHub;

    constructor(
        IPoolManager _manager,
        ITaxController _taxController,
        IJITHub _jitHub
    ) HookCallableBaseHook(_manager) {
        taxController = _taxController;
        jitHub = _jitHub;
    }

    /**
     * @inheritdoc HookCallableBaseHook
     */
    function _afterAddLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata addLiquidityParams,
        BalanceDelta,
        BalanceDelta feeDelta,
        bytes calldata enteredEncodedTimeCommitment
    ) internal virtual override returns (bytes4, BalanceDelta memory) {
        TimeCommitment enteredTimeCommitment = TimeCommitment.wrap(
            abi.decode(enteredEncodedTimeCommitment, (uint96))
        );

        bytes32 positionKey = liquidityRouter.calculatePositionKey(
            addLiquidityParams.tickLower,
            addLiquidityParams.tickUpper,
            addLiquidityParams.salt
        );

        taxController.updateTaxAccount(
            positionKey,
            poolKey,
            feeDelta,
            enteredTimeCommitment
        );

        try
            taxController.collectFeeRevenue(poolKey, positionKey, feeDelta)
        {} catch (bytes memory reason) {
            bytes4 expectedSelector = ITaxController
                .InvalidTimeCommitment___ActionOnlyAvailableToJIT
                .selector;
            bool isJIT;
            assembly ("memory-safe") {
                let actualSelector := mload(add(reason, 32))
                actualSelector := shr(224, actualSelector)
                isJIT := eq(actualSelector, expectedSelector)
            }
        }

        return (
            IHooks.afterAddLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
        );
    }

    /**
     * @inheritdoc HookCallableBaseHook
     */
    function _beforeSwap(
        address routerSender,
        PoolKey calldata poolKey,
        SwapParams calldata swapParams,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        JITLiquidityResult memory jitLiquidityResult = jitHub
            .calculateJITLiquidityParamsForSwap(
                routerSender,
                poolKey,
                swapParams
            );

        poolManager.modifyLiquidity(
            poolKey,
            jitLiquidityResult.jitLiquidityParams,
            abi.encode(toTimeCommitment(JIT_FLAG))
        );

        return (
            IHooks.beforeSwap.selector,
            toBeforeSwapDelta(int128(0), int128(0)),
            0
        );
    }

    /**
     * @inheritdoc HookCallableBaseHook
     */
    function _afterSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        return (IHooks.afterSwap.selector, int128(0));
    }

    /**
     * @inheritdoc HookCallableBaseHook
     */
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: true,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: true,
                afterAddLiquidityReturnDelta: true,
                afterRemoveLiquidityReturnDelta: true
            });
    }
}