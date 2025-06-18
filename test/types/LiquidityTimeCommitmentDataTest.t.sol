// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../helpers/LiquidityTimeCommitmentDataStateHelper.sol";

/// @title LiquidityTimeCommitmentDataTest
/// @notice This contract contains unit tests for the LiquidityTimeCommitmentData library.
/// @dev This contract is meant to be used only in unit tests.
contract LiquidityTimeCommitmentDataTest is
    LiquidityTimeCommitmentDataStateHelper
{
    LiquidityTimeCommitmentWrapper liquidityTimeCommitmentDataLibrary;
    function setUp() public {
        deployAndMint2Currencies();
        liquidityTimeCommitmentDataLibrary = new LiquidityTimeCommitmentWrapper();
        deployCodeTo(
            "LiquidityTimeCommitmentWrapper.sol",
            address(liquidityTimeCommitmentDataLibrary)
        );
    }

    /**
     * @notice Tests retrieval of TimeCommitment from JIT LiquidityTimeCommitmentData.
     * @dev Verifies both the success case with valid data and failure case with invalid data.
     * It asserts that the decoded TimeCommitment is correctly set as a JIT commitment
     * and that invalid hook data reverts with an appropriate error.
     */
    function test__Unit__getTimeCommitmentFromJitLiquidityTimeCommitmentData()
        public
    {
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = stateHelper__JITCommitmentDefaultPositiveLiquiditySettings();
        TimeCommitment
            memory timeCommitment = liquidityTimeCommitmentDataLibrary
                .getTimeCommitment(liquidityTimeCommitmentData);
        assertEq(timeCommitment.isJIT, true);
        assertEq(timeCommitment.startingBlock, block.number + 1);
        assertEq(timeCommitment.endingBlock, block.number + 1);
        LiquidityTimeCommitmentData
            memory invalidLiquidityTimeCommitmentData = LiquidityTimeCommitmentData({
                liquidityProvider: liquidityTimeCommitmentData
                    .liquidityProvider,
                poolKey: liquidityTimeCommitmentData.poolKey,
                liquidityParams: liquidityTimeCommitmentData.liquidityParams,
                hookData: bytes("garbage"),
                settleUsingBurn: true,
                takeClaims: true
            });
        vm.expectRevert(
            InvalidRawData___RawDataDoesNotDecodeToTimeCommitment.selector
        );
        liquidityTimeCommitmentDataLibrary.getTimeCommitment(
            invalidLiquidityTimeCommitmentData
        );
    }
    /// @notice Tests retrieval of TimeCommitment from PLP LiquidityTimeCommitmentData.
    /// @dev Verifies both the success case with valid data and failure case with invalid data.
    /// It asserts that the decoded TimeCommitment is correctly set as a PLP commitment
    /// and that invalid hook data reverts with an appropriate error.
    function test__Unit__getTimeCommitmentFromPlpLiquidityTimeCommitmentData()
        public
    {
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = stateHelper__PLPCommitmentDefaultPositiveLiquiditySettings();
        TimeCommitment
            memory timeCommitment = liquidityTimeCommitmentDataLibrary
                .getTimeCommitment(liquidityTimeCommitmentData);
        assertEq(timeCommitment.isJIT, false);
        assertEq(timeCommitment.startingBlock, block.number + 1);
        assertEq(timeCommitment.endingBlock, block.number + 5);
        LiquidityTimeCommitmentData
            memory invalidLiquidityTimeCommitmentData = LiquidityTimeCommitmentData({
                liquidityProvider: liquidityTimeCommitmentData
                    .liquidityProvider,
                poolKey: liquidityTimeCommitmentData.poolKey,
                liquidityParams: liquidityTimeCommitmentData.liquidityParams,
                hookData: bytes("garbage"),
                settleUsingBurn: true,
                takeClaims: true
            });
        vm.expectRevert(
            InvalidRawData___RawDataDoesNotDecodeToTimeCommitment.selector
        );
        liquidityTimeCommitmentDataLibrary.getTimeCommitment(
            invalidLiquidityTimeCommitmentData
        );
    }

    /// @notice Tests the getPositionKey function of the LiquidityTimeCommitmentData library.
    /// @dev Verifies that the function returns a valid position key.
    function test__Unit__getPositionKey() public {
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = stateHelper__JITCommitmentDefaultPositiveLiquiditySettings();
        bytes32 positionKey = liquidityTimeCommitmentDataLibrary.getPositionKey(
            liquidityTimeCommitmentData,
            liquidityTimeCommitmentData.liquidityParams
        );
        assertLt(0, uint256(positionKey));
    }

    /// @notice Tests the isLookingToAddLiquidity function of the LiquidityTimeCommitmentData library.
    /// @dev Verifies that the function returns true when the liquidityDelta is greater than 0.
    function test__Unit__isLookingToAddLiquidity() public {
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = stateHelper__JITCommitmentDefaultPositiveLiquiditySettings();
        bool isLookingToAddLiquidity = liquidityTimeCommitmentDataLibrary
            .isLookingToAddLiquidity(liquidityTimeCommitmentData);
        assertEq(isLookingToAddLiquidity, true);
    }

    /// @notice Tests the isLookingToRemoveLiquidity function of the LiquidityTimeCommitmentData library.
    /// @dev Verifies that the function returns true when the liquidityDelta is less than 0.
    function test__Unit__isLookingToRemoveLiquidity() public {
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = stateHelper__JITCommitmentDefaultNegativeLiquiditySettings();
        bool isLookingToRemoveLiquidity = liquidityTimeCommitmentDataLibrary
            .isLookingToRemoveLiquidity(liquidityTimeCommitmentData);
        assertEq(isLookingToRemoveLiquidity, true);
    }

    /// @notice Tests the fromBytesToLiquidityTimeCommitmentData function of the LiquidityTimeCommitmentData library.
    /// @dev Verifies that the function returns a valid LiquidityTimeCommitmentData from bytes.
    /// @dev Verifies that the function fails with an appropriate error if the bytes do not decode to a valid LiquidityTimeCommitmentData.
    function test__Unit__fromBytesToLiquidityTimeCommitmentData() public {
        LiquidityTimeCommitmentData
            memory liquidityTimeCommitmentData = stateHelper__JITCommitmentDefaultPositiveLiquiditySettings();
        bytes memory encodedLiquidityTimeCommitmentData = abi.encode(
            liquidityTimeCommitmentData
        );
        LiquidityTimeCommitmentData
            memory decodedLiquidityTimeCommitmentData = liquidityTimeCommitmentDataLibrary
                .fromBytesToLiquidityTimeCommitmentData(
                    encodedLiquidityTimeCommitmentData
                );
        TimeCommitment
            memory timeCommitment = liquidityTimeCommitmentDataLibrary
                .getTimeCommitment(decodedLiquidityTimeCommitmentData);
        assertEq(timeCommitment.isJIT, true);
        assertEq(timeCommitment.startingBlock, block.number + 1);
        assertEq(timeCommitment.endingBlock, block.number + 1);
        bytes memory encodedInvalidLiquidityTimeCommitmentData = abi.encode(
            LiquidityTimeCommitmentData({
                liquidityProvider: liquidityTimeCommitmentData
                    .liquidityProvider,
                poolKey: liquidityTimeCommitmentData.poolKey,
                liquidityParams: liquidityTimeCommitmentData.liquidityParams,
                hookData: bytes("garbage"),
                settleUsingBurn: true,
                takeClaims: true
            })
        );

        vm.expectRevert(
            InvalidHookData___rawDataDoesNotDecodeToLiquidityTimeCommitmentData
                .selector
        );
        liquidityTimeCommitmentDataLibrary
            .fromBytesToLiquidityTimeCommitmentData(
                encodedInvalidLiquidityTimeCommitmentData
            );
    }
    // TODO: Missing coverage for the rest of functions ...
}
