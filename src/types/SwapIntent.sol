
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ===================================================================================================
//                  "Intent: How much of currency1 can I buy given a specified amount of currency0"
//    "Trader deposits currency0 "             "Trader enters 0"            "Trader receives currency1"   
//    swapParams.amountSpecified < 0     ^         zeroForOne         -->     amountUnspecified > 0
//
//                "Intent: How much of currency0 can I buy given a specified amount of currency1"
//    "Trader deposits currency1"               "Trader enters 1"         "Trader receives currency0"
//     swapParams.amountSpecified < 0      ^       !zeroForOne        -->   amountUnspecified > 0
//
//                "Intent: How much currency0 must I sell to receive a specified amount of currency1"
//     swapParams.amountSpecified > 0     ^        zeroForOne        -->   amountUnspecified < 0
//
//                "Intent: How much currency1 must I sell to receive a specified amount of currency0"
//     swapParams.amountSpecified > 0     ^        !zeroForOne       -->   amountUnspecified < 0
// ====================================================================================================

/**
 * @dev SwapIntent enum representing the different types of swap intents
 * Based on the combination of zeroForOne and isExactInput parameters
 */
enum SwapIntent {
    // Exact input swap: currency0 -> currency1 (zeroForOne = true, isExactInput = true)
    EXACT_INPUT_ZERO_FOR_ONE,
    // Exact input swap: currency1 -> currency0 (zeroForOne = false, isExactInput = true)  
    EXACT_INPUT_ONE_FOR_ZERO,
    // Exact output swap: currency0 -> currency1 (zeroForOne = true, isExactInput = false)
    EXACT_OUTPUT_ZERO_FOR_ONE,
    // Exact output swap: currency1 -> currency0 (zeroForOne = false, isExactInput = false)
    EXACT_OUTPUT_ONE_FOR_ZERO
}

using SwapIntentLibrary for SwapIntent global;

library SwapIntentLibrary {
    
    /**
     * @dev Determines the swap intent based on zeroForOne and isExactInput parameters
     * @param zeroForOne True if swapping from currency0 to currency1, false otherwise
     * @param _isExactInput True if the input amount is specified (exact input), false if output amount is specified (exact output)
     * @return The corresponding SwapIntent enum value
     */
    function swapIntent(
        bool zeroForOne,
        bool _isExactInput
    ) internal pure returns (SwapIntent) {
        if (zeroForOne && _isExactInput) {
            return SwapIntent.EXACT_INPUT_ZERO_FOR_ONE;
        } else if (!zeroForOne && _isExactInput) {
            return SwapIntent.EXACT_INPUT_ONE_FOR_ZERO;
        } else if (zeroForOne && !_isExactInput) {
            return SwapIntent.EXACT_OUTPUT_ZERO_FOR_ONE;
        } else {
            return SwapIntent.EXACT_OUTPUT_ONE_FOR_ZERO;
        }
    }

    /**
     * @dev Determines swap intent from amountSpecified and zeroForOne parameters
     * @param amountSpecified The amount specified in the swap (negative for exact input, positive for exact output)
     * @param zeroForOne True if swapping from currency0 to currency1, false otherwise
     * @return The corresponding SwapIntent enum value
     */
    function swapIntentFromAmount(
        int256 amountSpecified,
        bool zeroForOne
    ) internal pure returns (SwapIntent) {
        bool _isExactInput = amountSpecified < 0;
        return swapIntent(zeroForOne, _isExactInput);
    }

    /**
     * @dev Checks if the swap intent is an exact input swap
     * @param intent The swap intent to check
     * @return True if it's an exact input swap, false otherwise
     */
    function isExactInput(SwapIntent intent) internal pure returns (bool) {
        return intent == SwapIntent.EXACT_INPUT_ZERO_FOR_ONE || 
               intent == SwapIntent.EXACT_INPUT_ONE_FOR_ZERO;
    }

    /**
     * @dev Checks if the swap intent is an exact output swap
     * @param intent The swap intent to check
     * @return True if it's an exact output swap, false otherwise
     */
    function isExactOutput(SwapIntent intent) internal pure returns (bool) {
        return intent == SwapIntent.EXACT_OUTPUT_ZERO_FOR_ONE || 
               intent == SwapIntent.EXACT_OUTPUT_ONE_FOR_ZERO;
    }

    /**
     * @dev Checks if the swap intent involves swapping from currency0 to currency1
     * @param intent The swap intent to check
     * @return True if swapping zero for one, false otherwise
     */
    function isZeroForOne(SwapIntent intent) internal pure returns (bool) {
        return intent == SwapIntent.EXACT_INPUT_ZERO_FOR_ONE || 
               intent == SwapIntent.EXACT_OUTPUT_ZERO_FOR_ONE;
    }

    /**
     * @dev Checks if the swap intent involves swapping from currency1 to currency0
     * @param intent The swap intent to check
     * @return True if swapping one for zero, false otherwise
     */
    function isOneForZero(SwapIntent intent) internal pure returns (bool) {
        return intent == SwapIntent.EXACT_INPUT_ONE_FOR_ZERO || 
               intent == SwapIntent.EXACT_OUTPUT_ONE_FOR_ZERO;
    }

    /**
     * @dev Returns a human-readable description of the swap intent
     * @param intent The swap intent to describe
     * @return A string describing the swap intent
     */
    function description(SwapIntent intent) internal pure returns (string memory) {
        if (intent == SwapIntent.EXACT_INPUT_ZERO_FOR_ONE) {
            return "Exact input: currency0 -> currency1";
        } else if (intent == SwapIntent.EXACT_INPUT_ONE_FOR_ZERO) {
            return "Exact input: currency1 -> currency0";
        } else if (intent == SwapIntent.EXACT_OUTPUT_ZERO_FOR_ONE) {
            return "Exact output: currency0 -> currency1";
        } else {
            return "Exact output: currency1 -> currency0";
        }
    }
}
