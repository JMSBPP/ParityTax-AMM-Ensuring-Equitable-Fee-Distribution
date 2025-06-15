// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC4626} from "forge-std/interfaces/IERC4626.sol";

struct LiquidityPositionAccounting {
    IERC4626 accountingCurrency0;
    IERC4626 accountingCurrency1;
}
