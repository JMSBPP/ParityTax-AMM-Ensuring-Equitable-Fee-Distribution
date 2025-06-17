// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import "v4-core/types/Currency.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

import "../helpers/LiquidityTimeCommitmentWrapper.sol";

contract LiquidityTimeCommitmentDataTest is Test, Deployers {
    using LiquidityTimeCommitmentDataLibrary for *;
    using CurrencyLibrary for Currency;
    using TimeCommitmentLibrary for *;

    address internal liquidityProvider = makeAddr("liquidityProvider");
    LiquidityTimeCommitmentWrapper liquidityTimeCommitmentDataLibrary;
    function setUp() public {
        deployAndMint2Currencies();
        liquidityTimeCommitmentDataLibrary = new LiquidityTimeCommitmentWrapper();
        deployCodeTo(
            "LiquidityTimeCommitmentWrapper.sol",
            address(liquidityTimeCommitmentDataLibrary)
        );
    }

    function test__Unit__getTimeCommitmentFromLiquidityTimeCommitmentData()
        public
    {
        vm.roll(21_200_900);
        TimeCommitment memory underlyingTimeCommitment = TimeCommitment(
            true,
            block.number + 1,
            block.number + 1
        );
        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        ModifyLiquidityParams memory liquidityParams = ModifyLiquidityParams({
            tickLower: -120,
            tickUpper: 120,
            liquidityDelta: 1000e18,
            salt: bytes32(0)
        });

        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = LiquidityTimeCommitmentData(
                liquidityProvider,
                poolKey,
                liquidityParams,
                underlyingTimeCommitment.toBytes(),
                true,
                true
            );

        TimeCommitment
            memory timeCommitment = liquidityTimeCommitmentDataLibrary
                .getTimeCommitment(liquidityTimeCommitmentData);
        assertEq(timeCommitment.isJIT, true);
        assertEq(timeCommitment.startingBlock, block.number + 1);
        assertEq(timeCommitment.endingBlock, block.number + 1);
        LiquidityTimeCommitmentData
            memory invalidLiquidityTimeCommitmentData = LiquidityTimeCommitmentData({
                liquidityProvider: liquidityProvider,
                poolKey: poolKey,
                liquidityParams: liquidityParams,
                hookData: bytes("garbage"),
                settleUsingBurn: true,
                takeClaims: true
            });
        vm.expectRevert(
            InvalidRawData___RawDataDoesNotDecodeToTimeCommitment.selector
        );
        liquidityTimeCommitmentDataLibrary.getTimeCommitment(
            invalidLiquidityTimeCommitmentData
        );
    }

    function test__Unit__getPositionKey() public {}
}
