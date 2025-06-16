// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/LiquidityTimeCommitmentData.sol";
import {Test, console} from "forge-std/Test.sol";
import "v4-core/types/Currency.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

contract LiquidityTimeCommitmentDataTest is Test, Deployers {
    using LiquidityTimeCommitmentDataLibrary for LiquidityTimeCommitmentData;
    using LiquidityTimeCommitmentDataLibrary for bytes;
    using CurrencyLibrary for Currency;
    using TimeCommitmentLibrary for *;

    address internal alice = makeAddr("Alice");
    function setUp() public {
        deployAndMint2Currencies();
    }

    function test___callDataThatDoesNotDecodeToTimeCommitmentReverts(
        bytes memory randomRawData
    ) public {
        // 1. We need to create a LiquidityTimeCommitmentData with invalid hookData

        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = LiquidityTimeCommitmentData({
                liquidityProvider: alice,
                poolKey: PoolKey({
                    currency0: currency0,
                    currency1: currency1,
                    fee: 3000,
                    tickSpacing: 60,
                    hooks: IHooks(address(0))
                }),
                liquidityParams: ModifyLiquidityParams({
                    liquidityDelta: 1000e18,
                    tickLower: -60000,
                    tickUpper: 60000,
                    salt: ""
                }),
                hookData: randomRawData,
                settleUsingBurn: true,
                takeClaims: true
            });

        if (randomRawData.length != TIME_COMMITMENT_DURATION_SIZE) {
            vm.expectRevert(
                InvalidHookData___HookDataDoesNotDecodeToTimeCommitment.selector
            );
        }

        if (randomRawData.length == TIME_COMMITMENT_DURATION_SIZE) {
            // 2. We need to decode the hookData
            TimeCommitment memory timeCommitment = abi.decode(
                randomRawData,
                (TimeCommitment)
            );
        }
    }
}
