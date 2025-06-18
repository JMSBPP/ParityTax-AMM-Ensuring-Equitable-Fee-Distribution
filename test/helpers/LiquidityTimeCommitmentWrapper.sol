// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/LiquidityTimeCommitmentData.sol";

/// @title LiquidityTimeCommitmentWrapper
/// @notice This contract is a wrapper for the LiquidityTimeCommitmentData library.
// It is used to test the library because of the issue
// https://github.com/foundry-rs/foundry/issues/3437#issuecomment-1267029138
contract LiquidityTimeCommitmentWrapper {
    using LiquidityTimeCommitmentDataLibrary for *;
    using TimeCommitmentLibrary for *;

    constructor() {}

    /// @notice Gets the TimeCommitment from a LiquidityTimeCommitmentData.
    /// @param liquidityTimeCommitmentData The LiquidityTimeCommitmentData to get the TimeCommitment from.
    /// @return timeCommitment The TimeCommitment of the LiquidityTimeCommitmentData.
    function getTimeCommitment(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = liquidityTimeCommitmentData.getTimeCommitment();
    }

    /// @notice Gets the position key from a LiquidityTimeCommitmentData.
    /// @dev This function gets the position key from a LiquidityTimeCommitmentData.
    /// @param liquidityTimeCommitmentData The LiquidityTimeCommitmentData to get the position key from.
    /// @param liquidityParams The ModifyLiquidityParams associated to the position key.
    /// @return positionKey The position key of the LiquidityTimeCommitmentData.
    function getPositionKey(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData,
        ModifyLiquidityParams memory liquidityParams
    ) external pure returns (bytes32 positionKey) {
        positionKey = liquidityTimeCommitmentData.getPositionKey(
            liquidityParams
        );
    }

    /// @notice Checks if the liquidity time commitment is looking to add liquidity.
    /// @dev This function checks if the liquidity time commitment is looking to add liquidity.
    /// @param liquidityTimeCommitmentData The LiquidityTimeCommitmentData to check.
    /// @return _isLookingToAddLiquidity True if the liquidity time commitment is looking to add liquidity, false otherwise.
    function isLookingToAddLiquidity(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external pure returns (bool _isLookingToAddLiquidity) {
        _isLookingToAddLiquidity = liquidityTimeCommitmentData
            .isLookingToAddLiquidity();
    }

    /// @notice Checks if the liquidity time commitment is looking to remove liquidity.
    /// @dev This function checks if the liquidity time commitment is looking to remove liquidity.
    /// @param liquidityTimeCommitmentData The LiquidityTimeCommitmentData to check.
    /// @return _isLookingToRemoveLiquidity True if the liquidity time commitment is looking to remove liquidity, false otherwise.
    function isLookingToRemoveLiquidity(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external pure returns (bool _isLookingToRemoveLiquidity) {
        _isLookingToRemoveLiquidity = liquidityTimeCommitmentData
            .isLookingToRemoveLiquidity();
    }

    function fromBytesToLiquidityTimeCommitmentData(
        bytes memory encodedLiquidityTimeCommitmentData
    )
        external
        view
        returns (LiquidityTimeCommitmentData memory liquidityTimeCommitmentData)
    {
        liquidityTimeCommitmentData = encodedLiquidityTimeCommitmentData
            .fromBytesToLiquidityTimeCommitmentData();
    }

    /**
     * @notice Sets the liquidity time commitment data for a given provider, pool, and parameters.
     * @dev This function sets the data and returns the validated LiquidityTimeCommitmentData.
     * @param liquidityProvider The address of the liquidity provider.
     * @param poolKey The pool key associated with the liquidity.
     * @param liquidityParams The parameters modifying the liquidity.
     * @param liquidityTimeCommitment The time commitment of the liquidity.
     * @param settleUsingBurn Boolean indicating if settlement should use burn.
     * @param takeClaims Boolean indicating if claims should be taken.
     * @return validatedLiquidityTimeCommitmentData The validated liquidity time commitment data.
     */
    function setLiquidityTimeCommitmentData(
        address liquidityProvider,
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        TimeCommitment memory liquidityTimeCommitment,
        bool settleUsingBurn,
        bool takeClaims
    )
        external
        view
        returns (
            LiquidityTimeCommitmentData
                memory validatedLiquidityTimeCommitmentData
        )
    {
        validatedLiquidityTimeCommitmentData = liquidityProvider
            .setLiquidityTimeCommitmentData(
                poolKey,
                liquidityParams,
                liquidityTimeCommitment,
                settleUsingBurn,
                takeClaims
            );
    }

    /**
     * @notice Validates the liquidity time commitment data.
     * @dev This function validates the liquidity time commitment data and returns the validated data.
     * @param liquidityTimeCommitmentData The LiquidityTimeCommitmentData to validate.
     * @return validatedLiquidityTimeCommitmentData The validated liquidity time commitment data.
     */
    function validateLiquidityTimeCommitmentData(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    )
        external
        view
        returns (
            LiquidityTimeCommitmentData
                memory validatedLiquidityTimeCommitmentData
        )
    {
        validatedLiquidityTimeCommitmentData = liquidityTimeCommitmentData
            .validateLiquidityTimeCommitmentData();
    }

    /**
     * @notice Encodes a LiquidityTimeCommitmentData to bytes.
     * @dev This function encodes a LiquidityTimeCommitmentData to bytes.
     * @param liquidityTimeCommitmentData The LiquidityTimeCommitmentData to encode.
     * @return encodedLiquidityTimeCommitmentData The encoded LiquidityTimeCommitmentData as bytes.
     */
    function fromLiquidityTimeCommitmentDataToBytes(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external view returns (bytes memory encodedLiquidityTimeCommitmentData) {
        encodedLiquidityTimeCommitmentData = liquidityTimeCommitmentData
            .fromLiquidityTimeCommitmentDataToBytes();
    }
}
