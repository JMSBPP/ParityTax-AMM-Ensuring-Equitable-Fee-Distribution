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
contract ParityTaxHook is HookCallableBaseHook, IParityTaxHook {
    using Position for address;
    using CurrencyLibrary for Currency;
    using CurrencySettler for Currency;
    using CurrencyDelta for Currency;
    using BalanceDeltaLibrary for BalanceDelta;
    using SafeCast for *;
    using StateLibrary for IPoolManager;

    //NOTE: This Hook receives addLiquidity requests from different capital
    // sources that send liquidity to a specific position via a general purpose
    // modifyLiquidityRouter and delegates the liquidity management of the posititon
    // to the respective liquidity manager subject to the lpType passed on the hookdta

    // The lpType passed is characterized by a positive block.timeStamp greater than
    // the current timeStamp if the timeCommitment does not have blok.timeStamp it is
    // taken as a JIT add LiquidityRequest

    // The JIT request is handled by a JITHook that is also a position manager

    // The PLP request is handled by a positionmanager with special services and
    // checks for locking liquiity removal actions based on the passed timeCommitment
    ITaxController private taxController;
    IJITHub private jitHub;
    constructor(
        IPoolManager _manager,
        ITaxController _taxController,
        IJITHub _jitHub
    ) HookCallableBaseHook(_manager) {
        taxController = _taxController;
        jitHub = _jitHub;
    }
    function _afterAddLiquidity(
        address liquidityRouter,
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata addLiquidityParams,
        BalanceDelta,
        BalanceDelta feeDelta,
        bytes calldata enteredEncodedTimeCommitment
    ) internal virtual override returns (bytes4, BalanceDelta) {
        TimeCommitment enteredTimeCommitment = TimeCommitment.wrap(
            abi.decode(enteredEncodedTimeCommitment, (uint96))
        );

        bytes32 positionKey = liquidityRouter.calculatePositionKey(
            addLiquidityParams.tickLower,
            addLiquidityParams.tickUpper,
            addLiquidityParams.salt
        );
        {
            //NOTE: This code chunk updates poolLiquidityTimeCommitments
            // accordingly

            taxController.updateTaxAccount(
                positionKey,
                poolKey,
                feeDelta,
                enteredTimeCommitment
            );
        }

        //NOTE: This code chunck is in charge of
        // collecting taxRevenue if the liquidity
        // provider is an JIT
        try
            taxController.collectFeeRevenue(poolKey, positionKey, feeDelta)
        {} catch (bytes memory reason) {
            //NOTE: The revert reason needs to equal the error
            //InvalidTimeCommitment___ActionOnlyAvailableToJIT();
            bytes4 expectedSelector = ITaxController
                .InvalidTimeCommitment___ActionOnlyAvailableToJIT
                .selector;
            bool isJIT;
            assembly ("memory-safe") {
                let actualSelector := mload(add(reason, 32))
                actualSelector := shr(224, actualSelector)
                isJIT := eq(actualSelector, expectedSelector)
            }
            // TODO: Here the taxController handles fee revenue collection
            // subject to the isJIT result
        }

        return (
            IHooks.afterAddLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
        );
    }
    function _beforeSwap(
        address routerSender,
        PoolKey calldata poolKey,
        SwapParams calldata swapParams,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        // NOTE: We return the JITLiquidityDelta if LP were to provide the
        // liquidity
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
        //
        // NOTE This is all must be stored on transient storage since at this point we do not know
        // if the trade will be fulfilled or not
        {
            //======== ADDING LIQUIDITY TO THE POOL =============
            // 1.
        }
        // IJITHub.TransientAddSwapOrder(
        //                           Analytics data logic
        //                           PoolKey poolKey
        //                           SwapParams swapParams);
        //
        return (
            IHooks.beforeSwap.selector,
            toBeforeSwapDelta(int128(0), int128(0)),
            0
        );
    }

    function _afterSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        // NOTE: On transient storage now we can retrieve the JIT lp's and their respective
        // ModifyLiquidityParams for adding liquidity to the pool
        {
            // ================================LIQUIDITY REMOVAL FULLLMENT===================
            // TODO With this data this function adds the liquidity of each lp until either
            // fulfillment or running out of JIT's willing to fulfill the trade
            // TODO: In the latest the remaining swap amount to be fulfilled needs to be fulfilled
            // by PLP's
        }
        {
            // =====================TAX REVENUE COLLECTION=====================
            // TODO: Here the taxController handles fee revenue collection for the JIT lp's
            // that fulfilled the trade subject to Analytics data and optimal tax setting
        }
        {
            //============LIQUIDITY TIME COMMITMENT MANAGEMENT================
            // TODO: We update the liquidity time commitments subject to the lp's that
            // ran out of money, or other cases ...
        }
        {
            //====================DELTA RESOLVERS ACCOUNTING =======================
            //TODO: At this point we make sure we settle all balances owed/owned to/from
            // the poolManager
        }
        return (IHooks.afterSwap.selector, int128(0));
    }
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
                afterAddLiquidity: true, //NOTE: This is to enforce deadlines on committed
                //positions,
                beforeRemoveLiquidity: true, //NOTE: This allows us to revert it the PLP has not
                // completed its deadline, we do not wat to use the
                // posm deadlienas it also restricts adding liquidity actions
                afterRemoveLiquidity: true, //NOTE This allows us to re-distribute tax
                // income or charge it, depending on the lpType
                beforeSwap: true, // NOTE This are the the JIT guarded add liquidity
                // requests
                afterSwap: true, // NOTE This are the the JIT guarded add liquidity
                // requests
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: true, //NOTE: This is to enable dynamic fees, which is what
                // how we realize dynacmi taxing
                afterAddLiquidityReturnDelta: true,
                afterRemoveLiquidityReturnDelta: true // NOTE: This allows the hook to gather revenue from
                // tax Controller to alter hookDeltas
            });
    }
}
