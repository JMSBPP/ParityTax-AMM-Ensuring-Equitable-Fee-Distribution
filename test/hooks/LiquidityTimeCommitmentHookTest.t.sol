// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import "../../src/hooks/LiquidityTimeCommitmentHook.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import "v4-core/types/PoolId.sol";
import "v4-core/types/Currency.sol";

contract LiquidityTimeCommitmentHookTest is Test, Deployers {
    using PoolIdLibrary for PoolId;
    using CurrencyLibrary for Currency;

    LiquidityTimeCommitmentHook private liquidityTimeCommitmentHook;

    function setUp() public {
        deployFreshManagerAndRouters();
        (currency0, currency1) = deployMintAndApprove2Currencies();

        address liquidityTimeCommitmentHookAddress = address(
            uint160(
                Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            )
        );

        deployCodeTo(
            "LiquidityTimeCommitmentHook.sol",
            abi.encode(manager),
            liquidityTimeCommitmentHookAddress
        );
        liquidityTimeCommitmentHook = LiquidityTimeCommitmentHook(
            liquidityTimeCommitmentHookAddress
        );
        (key, ) = initPool(
            currency0,
            currency1,
            liquidityTimeCommitmentHook,
            3000,
            SQRT_PRICE_1_1
        );

        IERC20Minimal(Currency.unwrap(key.currency0)).approve(
            liquidityTimeCommitmentHookAddress,
            1000 ether
        );

        IERC20Minimal(Currency.unwrap(key.currency1)).approve(
            liquidityTimeCommitmentHookAddress,
            1000 ether
        );

        vm.roll(100);
    }
    function helper___removeLiquidityTimeLocked100to123() internal {
        vm.startPrank(address(this));
        modifyLiquidityRouter.modifyLiquidity(
            key,
            REMOVE_LIQUIDITY_PARAMS,
            abi.encode(address(this))
        );
        vm.stopPrank();
    }
    function helper___addLiquidityTimeLocked100to123()
        internal
        returns (
            TimeCommitment memory timeCommitment,
            bytes32 lpPositionKey,
            PoolId poolId
        )
    {
        vm.startPrank(address(this));
        modifyLiquidityRouter.modifyLiquidity(
            key,
            LIQUIDITY_PARAMS,
            abi.encode(
                TimeCommitment({
                    liquidityProvider: address(this),
                    longTerm: true,
                    numberOfBlocks: uint256(23),
                    startingBlockNumber: uint256(100)
                })
            )
        );

        (lpPositionKey, poolId) = liquidityTimeCommitmentHook
            .getTimeCommitmentKeys(address(this), key, LIQUIDITY_PARAMS);

        timeCommitment = liquidityTimeCommitmentHook
            .getPositionPoolTimeCommitment(lpPositionKey, poolId);
        vm.stopPrank();
    }
    function test__shouldSetWithdrawalLock() public {
        (
            TimeCommitment memory timeCommitment,
            ,

        ) = helper___addLiquidityTimeLocked100to123();
        assertEq(timeCommitment.startingBlockNumber, 100);
        assertEq(timeCommitment.numberOfBlocks, 23);
    }

    function test__shouldPreventLiquidityWithdrawalUnderLock() external {
        helper___addLiquidityTimeLocked100to123();
        for (uint256 newBlock = 0; newBlock <= 23; newBlock++) {
            vm.roll(100 + newBlock);
            if (block.number < 123) {
                vm.expectRevert();
                helper___removeLiquidityTimeLocked100to123();
            }
        }
    }
}
