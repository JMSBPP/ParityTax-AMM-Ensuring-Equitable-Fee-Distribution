// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ToxicityLevel
 * @author j-money-11
 * @notice Defines a custom type to represent the "toxicity" of a swap.
 * @dev This is currently a placeholder. A more complex implementation could use this
 * to help the JITHub make more informed decisions about providing JIT liquidity.
 * For example, a high toxicity level might indicate a trade from an informed trader,
 * which is riskier for a JIT LP.
 */
type ToxicityLevel is uint8;

using ToxicityLevelLibrary for ToxicityLevel global;

/**
 * @title ToxicityLevelLibrary
 * @notice A library for handling operations related to the ToxicityLevel type.
 * @dev This library is currently a placeholder for future functionality.
 */
library ToxicityLevelLibrary {}