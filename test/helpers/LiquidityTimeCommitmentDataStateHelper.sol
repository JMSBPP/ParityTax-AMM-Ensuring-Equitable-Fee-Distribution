// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@uniswap/v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test, console} from "forge-std/Test.sol";
import "../helpers/LiquidityTimeCommitmentWrapper.sol";
import "v4-core/types/Currency.sol";

/// @title LiquidityTimeCommitmentDataStateHelper
/// @notice A helper contract for setting up states used in unit tests for LiquidityTimeCommitmentData.
/// @dev This contract is meant to be used only in unit tests.
contract LiquidityTimeCommitmentDataStateHelper is Test, Deployers {
    using LiquidityTimeCommitmentDataLibrary for *;
    using CurrencyLibrary for Currency;
    using TimeCommitmentLibrary for *;

    /**
     * @dev The default liquidity provider address used in tests.
     */
    address internal liquidityProvider = makeAddr("liquidityProvider");

    /**
     * @notice Returns the default positive liquidity settings.
     * @dev Pool key and liquidity parameters are set to default values for positive liquidity.
     * @return poolKey The default pool key for positive liquidity.
     * @return liquidityParams The default liquidity parameters for positive liquidity.
     */
    function stateHelper_DefaultPositiveLiquiditySettings()
        internal
        view
        returns (
            PoolKey memory poolKey,
            ModifyLiquidityParams memory liquidityParams
        )
    {
        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        liquidityParams = ModifyLiquidityParams({
            tickLower: -120,
            tickUpper: 120,
            liquidityDelta: 1000e18,
            salt: bytes32(0)
        });
    }
    /**
     * @notice Returns the default negative liquidity settings.
     * @dev Pool key and liquidity parameters are set to default values for negative liquidity.
     * @return poolKey The default pool key for negative liquidity.
     * @return liquidityParams The default liquidity parameters for negative liquidity.
     */
    function stateHelper_DefaultNegativeLiquiditySettings()
        internal
        view
        returns (
            PoolKey memory poolKey,
            ModifyLiquidityParams memory liquidityParams
        )
    {
        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        liquidityParams = ModifyLiquidityParams({
            tickLower: -120,
            tickUpper: 120,
            liquidityDelta: -1000e18,
            salt: bytes32(0)
        });
    }
    /**
     * @notice Sets up default positive liquidity settings for JIT commitment.
     * @dev Rolls the block number to a specific value and sets up the pool key and liquidity parameters.
     * @return jitLiquidityTimeCommitmentData The initialized LiquidityTimeCommitmentData for JIT.
     */
    function stateHelper__JITCommitmentDefaultPositiveLiquiditySettings()
        internal
        returns (
            LiquidityTimeCommitmentData memory jitLiquidityTimeCommitmentData
        )
    {
        vm.roll(21_200_900);
        TimeCommitment memory underlyingTimeCommitment = TimeCommitment(
            true,
            block.number + 1,
            block.number + 1
        );
        (
            PoolKey memory poolKey,
            ModifyLiquidityParams memory liquidityParams
        ) = stateHelper_DefaultPositiveLiquiditySettings();

        jitLiquidityTimeCommitmentData = LiquidityTimeCommitmentData(
            liquidityProvider,
            poolKey,
            liquidityParams,
            underlyingTimeCommitment.toBytes(),
            true,
            true
        );
    }

    /**
     * @notice Sets up default negative liquidity settings for JIT commitment.
     * @dev Rolls the block number to a specific value and sets up the pool key and liquidity parameters.
     * @return jitLiquidityTimeCommitmentData The initialized LiquidityTimeCommitmentData for JIT.
     */
    function stateHelper__JITCommitmentDefaultNegativeLiquiditySettings()
        internal
        returns (
            LiquidityTimeCommitmentData memory jitLiquidityTimeCommitmentData
        )
    {
        vm.roll(21_200_900);
        TimeCommitment memory underlyingTimeCommitment = TimeCommitment(
            true,
            block.number + 1,
            block.number + 1
        );
        (
            PoolKey memory poolKey,
            ModifyLiquidityParams memory liquidityParams
        ) = stateHelper_DefaultNegativeLiquiditySettings();

        jitLiquidityTimeCommitmentData = LiquidityTimeCommitmentData(
            liquidityProvider,
            poolKey,
            liquidityParams,
            underlyingTimeCommitment.toBytes(),
            true,
            true
        );
    }

    /**
     * @notice Sets up default positive liquidity settings for PLP commitment.
     * @dev Rolls the block number to a specific value and sets up the pool key and liquidity parameters.
     * @return plpLiquidityTimeCommitmentData The initialized LiquidityTimeCommitmentData for PLP.
     */
    function stateHelper__PLPCommitmentDefaultPositiveLiquiditySettings()
        internal
        returns (
            LiquidityTimeCommitmentData memory plpLiquidityTimeCommitmentData
        )
    {
        vm.roll(21_200_900);
        (
            PoolKey memory poolKey,
            ModifyLiquidityParams memory liquidityParams
        ) = stateHelper_DefaultPositiveLiquiditySettings();
        TimeCommitment memory underlyingTimeCommitment = TimeCommitment(
            false,
            block.number + 1,
            block.number + 5
        );

        plpLiquidityTimeCommitmentData = LiquidityTimeCommitmentData(
            liquidityProvider,
            poolKey,
            liquidityParams,
            underlyingTimeCommitment.toBytes(),
            true,
            true
        );
    }
}
