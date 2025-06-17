// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "./TimeCommitment.sol";
import {Position} from "v4-core/libraries/Position.sol";

uint256 constant LIQIDITY_TIME_COMMITMENT_DATA_SIZE = 0x220; //544

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
error InvalidHookData___rawDataDoesNotDecodeToLiquidityTimeCommitmentData();

/// @title Liquidity Callback Data Library
/// @dev Provides functions for handling LiquidityCallbackData.
library LiquidityTimeCommitmentDataLibrary {
    using TimeCommitmentLibrary for *;
    using Position for *; // Allows us to query positionKeys to associate position keys with time commitments

    /**
     * @dev Retrieves the TimeCommitment from the given LiquidityCallbackData.
     *      Validates that the hookData in LiquidityCallbackData decodes to a TimeCommitment.
     * @param liquidityTimeCommitmentData The LiquidityCallbackData containing the encoded TimeCommitment.
     * @return validatedTimeCommitment The decoded TimeCommitment.
     */
    function getTimeCommitment(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) internal view returns (TimeCommitment memory validatedTimeCommitment) {
        validatedTimeCommitment = liquidityTimeCommitmentData
            .hookData
            .fromBytesToTimeCommitment();
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
        if (
            encodedLiquidityTimeCommitmentData.length !=
            LIQIDITY_TIME_COMMITMENT_DATA_SIZE
        ) {
            revert InvalidHookData___rawDataDoesNotDecodeToLiquidityTimeCommitmentData();
        }
        LiquidityTimeCommitmentData memory _liquidityTimeCommitmentData = abi
            .decode(
                encodedLiquidityTimeCommitmentData,
                (LiquidityTimeCommitmentData)
            );
        TimeCommitment memory timeCommitment = getTimeCommitment(
            _liquidityTimeCommitmentData
        );
        liquidityTimeCommitmentData = setLiquidityTimeCommitmentData(
            _liquidityTimeCommitmentData.liquidityProvider,
            _liquidityTimeCommitmentData.poolKey,
            _liquidityTimeCommitmentData.liquidityParams,
            timeCommitment,
            _liquidityTimeCommitmentData.settleUsingBurn,
            _liquidityTimeCommitmentData.takeClaims
        );
    }

    function setLiquidityTimeCommitmentData(
        address liquidityProvider,
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        TimeCommitment memory liquidityTimeCommitment,
        bool settleUsingBurn,
        bool takeClaims
    )
        internal
        view
        returns (
            LiquidityTimeCommitmentData
                memory validatedLiquidityTimeCommitmentData
        )
    {
        bytes memory validatedUnderlyingHookData = liquidityTimeCommitment
            .toBytes();

        validatedLiquidityTimeCommitmentData = LiquidityTimeCommitmentData({
            liquidityProvider: liquidityProvider,
            poolKey: poolKey,
            liquidityParams: liquidityParams,
            hookData: validatedUnderlyingHookData,
            settleUsingBurn: settleUsingBurn,
            takeClaims: takeClaims
        });
    }
    function validateLiquidityTimeCommitmentData(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    )
        internal
        view
        returns (
            LiquidityTimeCommitmentData
                memory validatedLiquidityTimeCommitmentData
        )
    {
        TimeCommitment memory underlyingTimeCommitment = getTimeCommitment(
            liquidityTimeCommitmentData
        );
        validatedLiquidityTimeCommitmentData = setLiquidityTimeCommitmentData(
            liquidityTimeCommitmentData.liquidityProvider,
            liquidityTimeCommitmentData.poolKey,
            liquidityTimeCommitmentData.liquidityParams,
            underlyingTimeCommitment,
            liquidityTimeCommitmentData.settleUsingBurn,
            liquidityTimeCommitmentData.takeClaims
        );
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
        LiquidityTimeCommitmentData
            memory _liquidityTimeCommitmentData = validateLiquidityTimeCommitmentData(
                liquidityTimeCommitmentData
            );
        // If this passes, we can continue
        // we need to encode LiquidityTimeCommitmentData
        // this is ..
        encodedLiquidityTimeCommitmentData = abi.encode(
            _liquidityTimeCommitmentData
        );
    }

    // function fromMsgDataToLiquidityTimeCommitmentData(
    //     bytes memory msgData
    // ) internal view returns (LiquidityTimeCommitmentData memory) {
    //     // This is the same as fromBytesToLiquidityTimeCommitmentData
    //     return fromBytesToLiquidityTimeCommitmentData(msgData);
    // }
}
