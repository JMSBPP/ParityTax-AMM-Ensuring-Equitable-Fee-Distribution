// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@uniswap/v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test, console} from "forge-std/Test.sol";
import "../helpers/LiquidityTimeCommitmentWrapper.sol";
import "v4-core/types/Currency.sol";
import "../../src/hooks/LiquidityTimeCommitmentHook.sol";
import "../../src/LiquidityTimeCommitmentManager.sol";
import "../../src/LiquidityTimeCommitmentHookStorage.sol";
import "../utils/LiquidityTimeCommitmentRouterTestSetUp.sol";

/// @title LiquidityTimeCommitmentHookStateHelper
/// @notice This contract serves as a state helper for testing the LiquidityTimeCommitmentHook.
/// @dev Inherits from Test, Deployers, and LiquidityTimeCommitmentRouterTestSetup to facilitate testing and state setup.
contract LiquidityTimeCommitmentHookStateHelper is
    Test,
    Deployers,
    LiquidityTimeCommitmentRouterTestSetup
{
    using TimeCommitmentLibrary for *;
    using LiquidityTimeCommitmentDataLibrary for *;

    LiquidityTimeCommitmentHook internal liquidityTimeCommitmentHook;

    address internal _plpLp = makeAddr("PLP");
    address internal _jitLp = makeAddr("JIT");

    /// @notice Sets up the hookData params for a JIT first time committed position.
    /// @dev Sets up the hookData params for a JIT first time committed position.
    /// Rolls the block number to a specific value, sets up the pool key and liquidity parameters.
    /// @return _hookData The initialized bytes for JIT commitment.
    function test__StateHelper_beforeAddLiquidity__JITFirstTimeCommitedPosition()
        internal
        returns (bytes memory _hookData)
    {
        vm.roll(100);
        vm.startPrank(_jitLp);
        TimeCommitment memory jitTimeCommitment = true.setTimeCommitment(
            block.number + 1, // startingBlock
            block.number + 1 // endingBlock
        );

        console.log("Starting Block:", jitTimeCommitment.startingBlock);
        console.log("Current Block:", block.number);
        console.log("Ending Block:", jitTimeCommitment.endingBlock);

        bytes memory hookData = jitTimeCommitment.toBytes();
        console.logBytes(hookData);
        console.log(hookData.length);
        console.log(IERC20(Currency.unwrap(currency0)).balanceOf(_jitLp));
        console.log(IERC20(Currency.unwrap(currency1)).balanceOf(_jitLp));
        IERC20(Currency.unwrap(currency0)).approve(
            address(liquidityTimeCommitmentHook),
            IERC20(Currency.unwrap(currency0)).balanceOf(_jitLp)
        );
        IERC20(Currency.unwrap(currency1)).approve(
            address(liquidityTimeCommitmentHook),
            IERC20(Currency.unwrap(currency1)).balanceOf(_jitLp)
        );
        _hookData = hookData;
        vm.stopPrank();
    }
}
