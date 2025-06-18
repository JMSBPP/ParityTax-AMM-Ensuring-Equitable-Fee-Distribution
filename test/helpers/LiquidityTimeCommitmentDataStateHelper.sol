// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@uniswap/v4-core/test/utils/Deployers.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test, console} from "forge-std/Test.sol";
import "../helpers/LiquidityTimeCommitmentWrapper.sol";
import "v4-core/types/Currency.sol";

contract LiquidityTimeCommitmentDataStateHelper is Test, Deployers {
    using LiquidityTimeCommitmentDataLibrary for *;
    using CurrencyLibrary for Currency;
    using TimeCommitmentLibrary for *;

    address internal liquidityProvider = makeAddr("liquidityProvider");

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
