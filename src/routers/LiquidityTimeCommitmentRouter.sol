// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-core/types/Currency.sol";
import "../types/LiquidityTimeCommitmentData.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {CurrencySettler} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "v4-core/libraries/TransientStateLibrary.sol";

import {Currency} from "v4-core/types/Currency.sol";
import {SafeCallback} from "v4-periphery/src/base/SafeCallback.sol";

import "../libs/LiquidityManagerHelper.sol";

error InvalidState___LiquidityChangeNotValid();
contract LiquidityTimeCommitmentRouter is SafeCallback {
    using TransientStateLibrary for IPoolManager;
    using StateLibrary for IPoolManager;
    using LiquidityTimeCommitmentDataLibrary for *;
    using TimeCommitmentLibrary for *;
    using LiquidityManagerHelper for *;
    constructor(IPoolManager _manager) SafeCallback(_manager) {}

    function modifyLiquidity(
        PoolKey memory key,
        ModifyLiquidityParams memory liquidityParams,
        bytes memory hookData
    )
        public
        payable
        returns (
            // bool settleUsingBurn,
            // bool takeClaims
            BalanceDelta delta
        )
    {
        TimeCommitment memory timeCommitment = hookData
            .fromBytesToTimeCommitment();
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData = msg
            .sender
            .setLiquidityTimeCommitmentData(
                key,
                liquidityParams,
                timeCommitment,
                true,
                true
            );

        if (liquidityTimeCommitmentData.isLookingToRemoveLiquidity()) {
            // 1. hookData is irrelevant because timeCommitment
            // is only enforced when ading liquidity
            // TODO: Perhaps for removing liquidity we might need
            // hookData, this is to be determined ...
            liquidityTimeCommitmentData.hookData = "";
            // TODO: However this means that we need to verify that the LP is
            // even allowed to remove liquidity considering the timeCommitment
            // that must had specified when added the liquidity
            // verifying here allows us to skip frther calls that waste gas ...
            // Addtionally if when querying the timeCommitment we find out that it
            // is JIT, we need to revert stating that JIT's withdraw liquidity
            // on the JITHook afterSwap Functions
        }
        // We get the underlying time Commitment
        // NOTE: this will revert if timeCommitment is not valid
        if (liquidityTimeCommitmentData.isLookingToAddLiquidity()) {
            liquidityTimeCommitmentData.getTimeCommitment();
        }
        // Now with all these checks we can forward to the
        // manager to allow us to further forward the data to
        // the hooks ...
        delta = abi.decode(
            poolManager.unlock(abi.encode(liquidityTimeCommitmentData)),
            (BalanceDelta)
        );
        // function unlock(bytes calldata data) external override returns (bytes memory result) {
        //     if (Lock.isUnlocked()) AlreadyUnlocked.selector.revertWith();

        //     Lock.unlock();

        //     // the caller does everything in this callback, including paying what they owe via calls to settle
        //     result = IUnlockCallback(msg.sender).unlockCallback(data);

        //     if (NonzeroDeltaCount.read() != 0) CurrencyNotSettled.selector.revertWith();
        //         Lock.lock();
        // }
        // This handles native ETH transfers
        // TODO: Verify if this is correct for our use case ...
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.ADDRESS_ZERO.transfer(msg.sender, ethBalance);
        }
    }
    // NOTE: At this point invalid withdrawal request have been addressed
    // we have also verified the timeCommitments are valid
    // we can only have the following requests:
    // --> Valid withdrawal requests from PLP's
    // --> Valid deposit requests from JIT's
    // --> Valid deposit requests from PLP's
    //===========PART OF THE ISSUE OF CurrencyNotSettled() ========

    event LiquidityDeltas(int128 dx, int128 dy);
    event LiquidityOnPosition(uint128 liquidityBefore, uint128 liquidityAfter);
    //===========================================================

    function _unlockCallback(
        bytes calldata data
    ) internal override returns (bytes memory) {
        bytes memory encodedLiquidityTimeCommitmentData = data;

        //NOTE: This is the same decoding done  on
        // PoolModifyLiquidityTest for the
        // CallbackData
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = encodedLiquidityTimeCommitmentData
                .fromBytesToLiquidityTimeCommitmentData();
        //NOTE: This is adddtional decoding/encoding
        // done here to get the TimeCommmitment
        // which is one of the reasons why we need
        // a Custom liquidity router
        bytes memory hookData = liquidityTimeCommitmentData
            .fromLiquidityTimeCommitmentDataToBytes();

        //NOTE: This is the same as in PoolModifyLiquidityTest

        (uint128 liquidityBefore, , ) = poolManager.getPositionInfo(
            liquidityTimeCommitmentData.poolKey.toId(),
            address(this), //QUESTION: Is the router
            // the owner of the position ?
            liquidityTimeCommitmentData.liquidityParams.tickLower,
            liquidityTimeCommitmentData.liquidityParams.tickUpper,
            liquidityTimeCommitmentData.liquidityParams.salt
        );

        //====FOR DEBUGGIN PURPOESES ONLY ======
        // TODO: From the liquidity params liquidityDelta which is
        // a int128 I wnat to get the respective
        // liquidityToBeAddedOnCurrency0,
        // liquidityToBeAddedOnCurrency1
        // NOTE: This is the same as in PoolModifyLiquidityTest
        // The modifyLiquidity request from the LP
        // get's forwarded to
        // router -> manager -> hook ->
        // liquidityManager -> manager -> router
        (BalanceDelta liquidityBalanceDelta, ) = poolManager.modifyLiquidity(
            liquidityTimeCommitmentData.poolKey,
            liquidityTimeCommitmentData.liquidityParams,
            hookData
        );
        //===========PART OF THE ISSUE OF CurrencyNotSettled() ========

        emit LiquidityDeltas(
            liquidityBalanceDelta.amount0(),
            liquidityBalanceDelta.amount1()
        );
        //===========================================================
        (uint128 liquidityAfter, , ) = poolManager.getPositionInfo(
            liquidityTimeCommitmentData.poolKey.toId(),
            address(this), //QUESTION: Is the router
            // the owner of the position ?
            liquidityTimeCommitmentData.liquidityParams.tickLower,
            liquidityTimeCommitmentData.liquidityParams.tickUpper,
            liquidityTimeCommitmentData.liquidityParams.salt
        );
        emit LiquidityOnPosition(liquidityBefore, liquidityAfter);
        if (
            !poolManager.invariantModifyingLiquidity(
                liquidityTimeCommitmentData.poolKey,
                liquidityTimeCommitmentData.liquidityProvider,
                address(this),
                liquidityBefore,
                liquidityTimeCommitmentData.liquidityParams,
                liquidityAfter
            )
        ) {
            revert InvalidState___LiquidityChangeNotValid();
        }

        // TODO: We need to perform the checks for liquidityAfter all the
        // internal routing from manager and hooks has been done
        return abi.encode(liquidityBalanceDelta);
    }
}
