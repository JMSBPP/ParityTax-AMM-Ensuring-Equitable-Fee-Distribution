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
import {LiquidityMath} from "v4-core/libraries/LiquidityMath.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {SafeCallback} from "v4-periphery/src/base/SafeCallback.sol";

import "../libs/LiquidityManagerHelper.sol";
import "../interfaces/ILiquidityTimeCommitmentRouter.sol";
error InvalidState___LiquidityChangeNotValid();
contract LiquidityTimeCommitmentRouter is
    SafeCallback,
    ILiquidityTimeCommitmentRouter
{
    using TransientStateLibrary for IPoolManager;
    using StateLibrary for IPoolManager;
    using LiquidityTimeCommitmentDataLibrary for *;
    using TimeCommitmentLibrary for *;
    using LiquidityManagerHelper for *;
    using LiquidityMath for uint128;
    constructor(IPoolManager _manager) SafeCallback(_manager) {}
    // TODO: We need to verify that the LP is
    // even allowed to remove liquidity considering the timeCommitment
    // that must had specified when added the liquidity
    // verifying here allows us to skip frther calls that waste gas ...
    // Addtionally if when querying the timeCommitment we find out that it
    // is JIT, we need to revert stating that JIT's withdraw liquidity
    // on the JITHook afterSwap Functions

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
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData = msg
            .sender
            .setLiquidityTimeCommitmentData(
                key,
                liquidityParams,
                hookData.fromBytesToTimeCommitment(),
                true,
                true
            );
        liquidityTimeCommitmentData.hookData = liquidityTimeCommitmentData
            .isLookingToAddLiquidity()
            ? liquidityTimeCommitmentData.getTimeCommitment().toBytes()
            : bytes("");
        delta = abi.decode(
            poolManager.unlock(abi.encode(liquidityTimeCommitmentData)),
            (BalanceDelta)
        );
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
    event AfterPoolManagerAddLiquidityDeltaCounts(uint256 count);
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
        //NOTE: This is the same as in PoolModifyLiquidityTest

        (uint128 liquidityBefore, , ) = poolManager.getPositionInfo(
            liquidityTimeCommitmentData.poolKey.toId(),
            address(this), //QUESTION: Is the router
            // the owner of the position ?
            liquidityTimeCommitmentData.liquidityParams.tickLower,
            liquidityTimeCommitmentData.liquidityParams.tickUpper,
            liquidityTimeCommitmentData.liquidityParams.salt
        );

        (
            BalanceDelta liquidityBalanceDelta,
            BalanceDelta feeBalanceDelta
        ) = poolManager.modifyLiquidity(
                liquidityTimeCommitmentData.poolKey,
                liquidityTimeCommitmentData.liquidityParams,
                liquidityTimeCommitmentData
                    .fromLiquidityTimeCommitmentDataToBytes()
            );
        //===========PART OF THE ISSUE OF CurrencyNotSettled() ========
        BalanceDelta principalDelta = liquidityBalanceDelta + feeBalanceDelta;

        emit LiquidityDeltas(
            feeBalanceDelta.amount0(),
            feeBalanceDelta.amount1()
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
        emit AfterPoolManagerAddLiquidityDeltaCounts(
            poolManager.getNonzeroDeltaCount()
        );
        // if (
        //     !poolManager.invariantModifyingLiquidity(
        //         liquidityTimeCommitmentData.poolKey,
        //         liquidityTimeCommitmentData.liquidityProvider,
        //         address(this),
        //         liquidityBefore,
        //         liquidityTimeCommitmentData.liquidityParams,
        //         liquidityAfter
        //     )
        // ) {
        //     revert InvalidState___LiquidityChangeNotValid();
        // }

        // TODO: We need to perform the checks for liquidityAfter all the
        // internal routing from manager and hooks has been done
        return abi.encode(liquidityBalanceDelta);
    }
}
