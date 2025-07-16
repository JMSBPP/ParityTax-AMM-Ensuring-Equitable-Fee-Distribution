// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Plan, Planner} from "v4-periphery/test/shared/Planner.sol";
import {V4Quoter} from "v4-periphery/src/lens/V4Quoter.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "v4-core/types/BalanceDelta.sol";
import {SharedStateSetUp} from "./shared/SharedStateSetUp.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";


uint256 constant JULY_8TH_TIMESTAMP = 1752012003;

contract ParityTaxHookJITLiquidityTest is Test, Deployers, SharedStateSetUp {
    using CurrencyLibrary for Currency;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address jit = address(this);

    function setUp() public {
        deployBaseProtocol(JULY_8TH_TIMESTAMP);
        {
            // NOTE: This is supposing a SQRT_PRICE of 1/2
            currency0.transfer(alice, uint256(type(uint160).max) / 2);
            currency1.transfer(bob, uint256(type(uint160).max));
        }

        (key, ) = initPool(
            currency0,
            currency1,
            IHooks(address(parityTaxHook)),
            Constants.FEE_MEDIUM,
            SQRT_PRICE_1_2
        );
    }

    function test__fuzz__swapJITLiquidity(uint256 _amountSpecified) external {
        int256 amountSpecified = int256(bound(_amountSpecified, uint256(type(uint32).max),uint256(type(uint128).max)));
        vm.startPrank(alice);
        {
            BalanceDelta swapDelta = swapRouter.swap(
                key,
                SwapParams({
                    zeroForOne: true,
                    amountSpecified: amountSpecified,
                    sqrtPriceLimitX96: SQRT_PRICE_1_2 -1
                }),
                PoolSwapTest.TestSettings({
                    takeClaims: false,
                    settleUsingBurn: false
                }),
                Constants.ZERO_BYTES
            );
        }
        vm.stopPrank();
    }
}
