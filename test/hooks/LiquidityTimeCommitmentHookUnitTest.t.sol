// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//====================CONTRACTS TO BE TESTED ==============

//========================TEST-UTILS =======================

import "../helpers/LiquidityTimeCommitmentHookStateHelper.sol";
import "v4-periphery/src/utils/HookMiner.sol";
import "../../src/interfaces/ILiquidityTimeCommitmentRouter.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
/// @title Liquidity Time Commitment Hook Test
/// @notice This contract tests the functionality of the Liquidity Time Commitment Hook
/// @dev This contract sets up a testing environment for verifying the behavior of the Liquidity Time Commitment Hook
contract LiquidityTimeCommitmenUnitHookTest is
    LiquidityTimeCommitmentHookStateHelper
{
    using TimeCommitmentLibrary for *;
    using LiquidityTimeCommitmentDataLibrary for *;
    using Hooks for IHooks;
    using HookMiner for address;
    using Position for *;
    using CurrencyLibrary for Currency;
    using TickMath for *;

    // 0. We need initally a couple of addresses one representing
    // A PLP and another representing a JIT

    LiquidityTimeCommitmentHookStorage
        internal liquidityTimeCommitmentHookStorage;
    LiquidityTimeCommitmentManager internal plpLiquidityManager;
    LiquidityTimeCommitmentManager internal jitLiquidityManager;
    function setUp() public {
        // TODO:

        // 1. We need to deploy the poolManager
        _deployLiquidityTimeCommitmentRouter();
        // 2. We need to deploy2currencies and deploy and approve the
        // liquidityTimeCommitmentRouter
        _deployMintAndApproveToLiquiditTimeCommitmentRouter2Currencies();
        // 3. We need to provide tokens to the providers, so they can interact with the pool
        console.log(
            "Circulating Supply Currency 0:",
            currency0.balanceOfSelf()
        );
        console.log(
            "Circulating Supply Currency 1:",
            currency1.balanceOfSelf()
        );
        currency0.transfer(_plpLp, 1000e30);
        currency1.transfer(_plpLp, 1000e30);

        currency0.transfer(_jitLp, 1000e30);
        currency1.transfer(_jitLp, 1000e30);

        // The Custom Router that considers the LiquidityTimeCommitmentCallbackData
        // is finally deployed
        // 5. With router, positionManager, poolManager out of the way
        // we need to deploy the LiquidityTimeCommitmentClassifier
        // and operators
        // 5.1 Deploy the LiquidityTimeCommitmentHookStorage
        liquidityTimeCommitmentHookStorage = new LiquidityTimeCommitmentHookStorage();
        (address liquidityTimeCommitmentHookAddress, ) = address(this).find(
            uint160(
                Hooks.BEFORE_SWAP_FLAG |
                    Hooks.AFTER_SWAP_FLAG |
                    Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                    Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                    Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG |
                    Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            ),
            type(LiquidityTimeCommitmentHook).creationCode,
            abi.encode(address(manager))
        );
        // NOTE: The address is valid for this testing environment
        deployCodeTo(
            "src/hooks/LiquidityTimeCommitmentHook.sol:LiquidityTimeCommitmentHook",
            abi.encode(
                address(manager),
                address(liquidityTimeCommitmentHookStorage)
            ),
            liquidityTimeCommitmentHookAddress
        );

        liquidityTimeCommitmentHook = LiquidityTimeCommitmentHook(
            liquidityTimeCommitmentHookAddress
        );

        address jitLiquidityManagerAddress = vm.computeCreate2Address(
            bytes32(uint256(0x0)),
            keccak256(type(LiquidityTimeCommitmentManager).creationCode),
            address(this)
        );

        deployCodeTo(
            "src/LiquidityTimeCommitmentManager.sol:LiquidityTimeCommitmentManager",
            abi.encode(address(manager)),
            jitLiquidityManagerAddress
        );

        jitLiquidityManager = LiquidityTimeCommitmentManager(
            jitLiquidityManagerAddress
        );

        address plpLiquidityManagerAddress = vm.computeCreate2Address(
            bytes32(uint256(0x1)),
            keccak256(type(LiquidityTimeCommitmentManager).creationCode),
            address(this)
        );

        deployCodeTo(
            "src/LiquidityTimeCommitmentManager.sol:LiquidityTimeCommitmentManager",
            abi.encode(address(manager)),
            plpLiquidityManagerAddress
        );

        plpLiquidityManager = LiquidityTimeCommitmentManager(
            plpLiquidityManagerAddress
        );
        //7 We finally init the Pool with
        (key, ) = initPool(
            currency0,
            currency1,
            liquidityTimeCommitmentHook,
            3000, // fee
            60, // tickSpacing
            SQRT_PRICE_1_2 // sqrtPriceX96
        );

        vm.roll(100);
    }

    /// @notice Tests the routing of add liquidity operation to JIT Liquidity Manager.
    /// @dev Sets up a JIT time commitment and routes liquidity modification through the JIT manager.
    /// The function logs block numbers, balance approvals, and liquidity amounts
    // for debugging.
    function test__beforeAddLiquidity__shouldRouteToJITLiquidityManager()
        external
    {
        bytes
            memory hookData = test__StateHelper_beforeAddLiquidity__JITFirstTimeCommitedPosition();

        console.log("Current Tick: ", SQRT_PRICE_1_2.getTickAtSqrtPrice());
        console.log("Position Tick Below: ", LIQUIDITY_PARAMS.tickLower);
        console.log("Position Tick Above: ", LIQUIDITY_PARAMS.tickUpper);

        vm.startPrank(_jitLp);

        _liquidityTimeCommitmentRouter.modifyLiquidity(
            key,
            LIQUIDITY_PARAMS,
            hookData
        );

        (uint256 amount0, uint256 amount1) = jitLiquidityManager
            .getClaimableLiquidityOnCurrencies(key);
        vm.stopPrank();

        console.log(
            "Expected JIT Liquidity Manager: ",
            address(jitLiquidityManager)
        );
        console.log("amount0: ", amount0);
        console.log("amount1: ", amount1);
    }
}
