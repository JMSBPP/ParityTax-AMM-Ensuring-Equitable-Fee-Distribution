// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "./TimeCommitment.sol";

/// @notice Structure to hold data related to liquidity callback.
/// @param liquidityProvider The address of the liquidity provider.
/// @param poolKey The key of the pool.
/// @param hookData Additional data used in the callback.
/// @param settleUsingBurn Indicates if settlement should use burn.
/// @param takeClaims Indicates if claims should be taken.
struct LiquidityTimeCommitmentData {
    address liquidityProvider;
    PoolKey poolKey;
    ModifyLiquidityParams liquidityParams;
    bytes hookData;
    bool settleUsingBurn;
    bool takeClaims;
}

/// @notice Error thrown when hook data does not decode to a valid TimeCommitment.
error InvalidHookData___HookDataDoesNotDecodeToTimeCommitment();

/// @title Liquidity Callback Data Library
/// @dev Provides functions for handling LiquidityCallbackData.
library LiquidityTimeCommitmentDataLibrary {
    using TimeCommitmentLibrary for bytes;
    using TimeCommitmentLibrary for TimeCommitment;

    /**
     * @dev Checks if the hookData in LiquidityCallbackData decodes to a valid TimeCommitment.
     *      It ensures that the length of hookData matches the length of an encoded TimeCommitment.
     *      If the lengths do not match, the function reverts with an error.
     * @param liquidityTimeCommitmentData The LiquidityCallbackData containing the hookData to validate.
     */
    function hookDataDecodesToEncodedTimeCommitment(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal pure {
        bytes memory hookData = liquidityTimeCommitmentData.hookData;
        if (
            hookData.length !=
            TimeCommitment({
                isJIT: true,
                startingBlock: type(uint256).max, // NOTICE: this is a placeholder
                endingBlock: type(uint256).max //         still valid timeCommitment
            }).toBytes().length
        ) {
            revert InvalidHookData___HookDataDoesNotDecodeToTimeCommitment();
        }
    }

    /**
     * @dev Retrieves the TimeCommitment from the given LiquidityCallbackData.
     *      Validates that the hookData in LiquidityCallbackData decodes to a TimeCommitment.
     * @param liquidityTimeCommitmentData The LiquidityCallbackData containing the encoded TimeCommitment.
     * @return timeCommitment The decoded TimeCommitment.
     */
    function getTimeCommitment(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal view returns (TimeCommitment memory timeCommitment) {
        hookDataDecodesToEncodedTimeCommitment(liquidityTimeCommitmentData);
        timeCommitment = liquidityTimeCommitmentData
            .hookData
            .fromBytesToTimeCommitment();
    }

    /**
     * @dev Checks if the callback data indicates that the user is looking to add liquidity.
     *      This is true if the liquidityDelta in the callback data is greater than 0.
     * @param liquidityTimeCommitmentData The callback data containing the user's intent.
     * @return _isLookingToAddLiquidity True if the user is looking to add liquidity, false if not.
     */
    function isLookingToAddLiquidity(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal pure returns (bool _isLookingToAddLiquidity) {
        _isLookingToAddLiquidity =
            liquidityTimeCommitmentData.liquidityParams.liquidityDelta > 0;
    }

    /**
     * @dev Checks if the callback data indicates that the user is looking to remove liquidity.
     *      This is true if the liquidityDelta in the callback data is less than 0.
     * @param liquidityTimeCommitmentData The callback data containing the user's intent.
     * @return _isLookingToRemoveLiquidity True if the user is looking to remove liquidity, false if not.
     */
    function isLookingToRemoveLiquidity(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal pure returns (bool _isLookingToRemoveLiquidity) {
        _isLookingToRemoveLiquidity =
            liquidityTimeCommitmentData.liquidityParams.liquidityDelta < 0;
    }
    /// @dev Decodes the bytes to a LiquidityCallbackData.
    /// @param encodedLiquidityTimeCommitmentData The bytes to decode.
    /// @return liquidityTimeCommitmentData The decoded LiquidityCallbackData.
    ///
    /// NOTE: This does not need to do additional checks since the callBackData
    /// is built from the modifyLiquidity params, thus it can not be wrong
    function fromBytesToLiquidityTimeCommitmentData(
        bytes memory encodedLiquidityTimeCommitmentData
    )
        internal
        pure
        returns (LiquidityTimeCommitmentData memory liquidityTimeCommitmentData)
    {
        liquidityTimeCommitmentData = abi.decode(
            encodedLiquidityTimeCommitmentData,
            (LiquidityTimeCommitmentData)
        );
    }
}
