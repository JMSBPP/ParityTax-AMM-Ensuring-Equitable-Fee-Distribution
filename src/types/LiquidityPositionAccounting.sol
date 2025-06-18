// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC4626} from "forge-std/interfaces/IERC4626.sol";

/**
 * @title LiquidityPositionAccounting
 * @notice This struct is used to keep track of the accounting currencies
 *         of a liquidity position.
 * @dev It contains the addresses of the ERC4626 vaults of the two currencies.
 */
struct LiquidityPositionAccounting {
    /// @notice The accounting currency vault of the first currency.
    IERC4626 accountingCurrency0;
    /// @notice The accounting currency vault of the second currency.
    IERC4626 accountingCurrency1;
}
