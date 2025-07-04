// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IParityTaxHook.sol";
import "./base/HookCallableBaseHook.sol";
import "../types/TimeCommitment.sol";

import "v4-core/libraries/Position.sol";
import "v4-core/types/BalanceDelta.sol";
import "v4-periphery/src/base/DeltaResolver.sol";
import "v4-core/libraries/CurrencyReserves.sol";
import {CurrencyLibrary} from "v4-core/types/Currency.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import "v4-core/libraries/TransientStateLibrary.sol";
import "v4-core/libraries/StateLibrary.sol";
import {CurrencyDelta} from "v4-core/libraries/CurrencyDelta.sol";
import {NonzeroDeltaCount} from "v4-core/libraries/NonzeroDeltaCount.sol";

import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import "../interfaces/ITaxController.sol";

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
    constructor(
        IPoolManager _manager,
        ITaxController _taxController
    ) HookCallableBaseHook(_manager) {
        taxController = _taxController;
    }
    event TimeCommitments(uint48 existing, uint48 newTimeCommitment);
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

        emit TimeCommitments(
            timeCommitmentValue(toTimeCommitment(UNINITIALIZED_FLAG)),
            timeCommitmentValue(enteredTimeCommitment)
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
        // {
        //     //NOTE: This code chunck is in charge of collectiong taxRevenue if the liquidity
        //     //provider is an LP
        //     try
        //         taxController.collectFeeRevenue(poolKey, positionKey, feeDelta)
        //     {} catch (bytes memory reason) {
        //         //NOTE: The revert reason needs to equal the error
        //         //InvalidTimeCommitment___ActionOnlyAvailableToJIT();
        //     }
        // }
        return (
            IHooks.afterAddLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
        );
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
