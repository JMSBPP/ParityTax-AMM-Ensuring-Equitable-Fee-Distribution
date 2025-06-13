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

//====ROUTER SPECIFIC =====

import "v4-core/test/PoolTestBase.sol";

error InvalidFunctionCaller___FunctionCallerMustBePoolManager();
abstract contract TimeCommitmentModifyLiquidityRouter is PoolTestBase {
    using StateLibrary for IPoolManager;
    using LiquidityTimeCommitmentDataLibrary for LiquidityTimeCommitmentData;
    using LiquidityTimeCommitmentDataLibrary for bytes;
    constructor(IPoolManager _manager) PoolTestBase(_manager) {}

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
        // We build the underlying liquidityTimeCommitmentData
        // from the fucntion params:
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = LiquidityTimeCommitmentData({
                liquidityProvider: msg.sender,
                poolKey: key,
                liquidityParams: liquidityParams,
                hookData: hookData,
                settleUsingBurn: true, // NOTE: We will need claim to handle liquidity
                takeClaims: true
            });

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
        // Now wil all these checks we can forward to the
        // manager to allow us to further forward the data to
        // the hooks ...
        delta = abi.decode(
            manager.unlock(abi.encode(liquidityTimeCommitmentData)),
            (BalanceDelta)
        );
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

    function unlockCallback(
        bytes memory encodedLiquidityTimeCommitmentData
    ) external returns (bytes memory encodedLiquidityBalanceDelta) {
        //0. It needs to check that the caller is the poolManager
        // TODO: There must be a more gas efficient way and secure
        // way to do this, we also need to consider re-entrancy and
        // other vulnerabilities
        if (msg.sender != address(manager))
            revert InvalidFunctionCaller___FunctionCallerMustBePoolManager();
        // 1. It needs to decode the Callback data, and consequently
        // ...
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = encodedLiquidityTimeCommitmentData
                .fromBytesToLiquidityTimeCommitmentData();
        // 1.1 ... the TimeCommitment inside it
        // TODO: Looks like we do not use this
        // TimeCommitment memory timeCommitment = liquidityTimeCommitmentData
        //     .getTimeCommitment();

        // TODO: We need to perform checks for liquidity before,
        // is this actually done querying the position since
        // liquidity is managed on vaults ?
        // (uint128 liquidityBefore, , ) = manager.getPositionInfo(
        //     liquidityTimeCommitmentData.poolKey.toId(),
        //     address(this),
        //     liquidityTimeCommitmentData.liquidityParams.tickLower,
        //     liquidityTimeCommitmentData.liquidityParams.tickUpper,
        //     liquidityTimeCommitmentData.liquidityParams.salt
        // );

        (BalanceDelta liquidityBalanceDelta, ) = manager.modifyLiquidity(
            liquidityTimeCommitmentData.poolKey,
            liquidityTimeCommitmentData.liquidityParams,
            liquidityTimeCommitmentData.hookData
        );

        // TODO: We need to perform the checks for liquidityAfter all the
        // internal routing from manager and hooks has been done
        encodedLiquidityBalanceDelta = abi.encode(liquidityBalanceDelta);
    }
}
