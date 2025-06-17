// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/types/LiquidityTimeCommitmentData.sol";

contract LiquidityTimeCommitmentWrapper {
    using LiquidityTimeCommitmentDataLibrary for *;
    using TimeCommitmentLibrary for *;

    constructor() {}

    function getTimeCommitment(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = liquidityTimeCommitmentData.getTimeCommitment();
    }

    function getPositionKey(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData,
        ModifyLiquidityParams memory liquidityParams
    ) external pure returns (bytes32 positionKey) {
        positionKey = liquidityTimeCommitmentData.getPositionKey(
            liquidityParams
        );
    }

    function isLookingToAddLiquidity(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external pure returns (bool _isLookingToAddLiquidity) {
        _isLookingToAddLiquidity = liquidityTimeCommitmentData
            .isLookingToAddLiquidity();
    }

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

    function fromLiquidityTimeCommitmentDataToBytes(
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external view returns (bytes memory encodedLiquidityTimeCommitmentData) {
        encodedLiquidityTimeCommitmentData = liquidityTimeCommitmentData
            .fromLiquidityTimeCommitmentDataToBytes();
    }
}
