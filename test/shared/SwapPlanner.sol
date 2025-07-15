// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// NOTE: We aim to have N swappers each with different
// endowments of the tokens on the Pool, which interact
// with the Pool

import {Plan, Planner} from "v4-periphery/test/shared/Planner.sol";
import {V4Quoter} from "v4-periphery/src/lens/V4Quoter.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
// TODO: To get started let's have 2 swappers one with only one token
// and the other with the other token
// TODO: There is only one lp which has 1/2 the liquidity of token0 on token1
// ---> u(r_x,r_y) = r_y + (1/2)r_x. ==> p_{Y/X} = 1/2 = SQRT_PRICE_1_2
// --> This is the initial price that corresponds to the utility function
// of the LP
// We have R_y = r_y + w*Y.balanceOf(swapperWithY)
// and     R_x = r_x + w*X.balanceOf(swapperWithX)
// subject to (R_x + w*X.balanceOf(swapperWithX))(R_Y - w*Y.balanceOf(swapperWithY)) = 1
