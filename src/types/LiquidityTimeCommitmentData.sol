// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "./TimeCommitment.sol";
import {Position} from "v4-core/libraries/Position.sol";

uint256 constant TIME_COMMITMENT_DURATION_SIZE = 60;

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
    using TimeCommitmentLibrary for *;
    using Position for *; // Allows us to query positionKeys to associate position keys with time commitments

    /**
     * @dev Checks if the hookData in LiquidityCallbackData decodes to a valid TimeCommitment.
     *      It ensures that the length of hookData matches the length of an encoded TimeCommitment.
     *      If the lengths do not match, the function reverts with an error.
     * @param liquidityTimeCommitmentData The LiquidityCallbackData containing the hookData to validate.
     */
    function hookDataDecodesToEncodedTimeCommitment(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal view returns (TimeCommitment memory tc) {
        bytes memory hookData = liquidityTimeCommitmentData.hookData;
        if (hookData.length != TIME_COMMITMENT_DURATION_SIZE) {
            revert InvalidHookData___HookDataDoesNotDecodeToTimeCommitment();
        }
        // Try decoding to ensure it's valid
        tc = hookData.fromBytesToTimeCommitment();
        // Optionally, add more semantic checks here
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
        timeCommitment = hookDataDecodesToEncodedTimeCommitment(
            liquidityTimeCommitmentData
        );
    }

    function getPositionKey(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData,
        ModifyLiquidityParams memory liquidityParams
    ) internal pure returns (bytes32 positionKey) {
        positionKey = liquidityTimeCommitmentData
            .liquidityProvider
            .calculatePositionKey(
                liquidityParams.tickLower,
                liquidityParams.tickUpper,
                liquidityParams.salt
            );
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
        view
        returns (LiquidityTimeCommitmentData memory liquidityTimeCommitmentData)
    {
        //TODO: Is check that the underlying timeCommitment is valid
        LiquidityTimeCommitmentData memory _liquidityTimeCommitmentData = abi
            .decode(
                encodedLiquidityTimeCommitmentData,
                (LiquidityTimeCommitmentData)
            );
        fromLiquidityTimeCommitmentDataToBytes(_liquidityTimeCommitmentData);
        // If this passes, we are all good ..
        liquidityTimeCommitmentData = _liquidityTimeCommitmentData;
    }

    /**
     * @dev Encodes the LiquidityCallbackData into bytes.
     *      This function first verifies that the hookData in the callback data
     *      decodes to a valid TimeCommitment using the `getTimeCommitment` function.
     *      If the hookData is invalid, the function reverts with an error.
     * @param liquidityTimeCommitmentData The callback data to encode.
     * @return encodedLiquidityTimeCommitmentData The encoded callback data.
     */
    function fromLiquidityTimeCommitmentDataToBytes(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal view returns (bytes memory encodedLiquidityTimeCommitmentData) {
        // NOTE: This also validates that the hookData decodes to a valid TimeCommitment
        getTimeCommitment(liquidityTimeCommitmentData);
        // If this passes, we can continue
        // we need to encode LiquidityTimeCommitmentData
        // this is ..
        encodedLiquidityTimeCommitmentData = abi.encode(
            liquidityTimeCommitmentData
        );
    }

    function fromMsgDataToLiquidityTimeCommitmentData(
        bytes memory msgData
    ) internal view returns (LiquidityTimeCommitmentData memory) {
        // This is the same as fromBytesToLiquidityTimeCommitmentData
        return fromBytesToLiquidityTimeCommitmentData(msgData);
    }
}
