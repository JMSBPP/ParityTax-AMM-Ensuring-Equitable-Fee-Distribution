// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//====================CONTRACTS TO BE TESTED ==============

//========================TEST-UTILS =======================

import {Test, console, Vm} from "forge-std/Test.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import "../utils/LiquidityTimeCommitmentRouterTestSetUp.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import "../../src/hooks/LiquidityTimeCommitmentHook.sol";
import "../../src/LiquidityTimeCommitmentManager.sol";

contract LiquidityTimeCommitmentHookTest is
    Test,
    LiquidityTimeCommitmentRouterTestSetup
{
    using TimeCommitmentLibrary for *;
    using LiquidityTimeCommitmentDataLibrary for *;
    using Hooks for IHooks;
    using HookMiner for address;
    using Position for *;
    using CurrencyLibrary for Currency;

    // 0. We need initally a couple of addresses one representing
    // A PLP and another representing a JIT
    address internal _plpLp = makeAddr("PLP");
    address internal _jitLp = makeAddr("JIT");

    //========CONTRACTS TO BE TESTED =============================
    LiquidityTimeCommitmentHook internal liquidityTimeCommitmentHook;
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
        currency0.transfer(_plpLp, 1000e18);
        currency1.transfer(_plpLp, 1000e18);

        currency0.transfer(_jitLp, 1000e18);
        currency1.transfer(_jitLp, 1000e18);

        // The Custom Router that considers the LiquidityTimeCommitmentCallbackData
        // is finally deployed
        // 5. With router, positionManager, poolManager out of the way
        // we need to deploy the LiquidityTimeCommitmentClassifier
        // and operators
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
            abi.encode(address(manager)),
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

    function test__beforeAddLiquidity__shouldRouteToJITLiquidityManager()
        external
    {
        //1. We set the hookData params for a JIT
        vm.roll(100);
        TimeCommitment memory jitTimeCommitment = TimeCommitmentLibrary
            .validateCommitment(
                true, // isJIT
                block.number + 1, // startingBlock
                block.number + 1 // endingBlock
            );
        console.log("Starting Block:", jitTimeCommitment.startingBlock);
        console.log("Current Block:", block.number);
        console.log("Ending Block:", jitTimeCommitment.endingBlock);

        bytes memory hookData = jitTimeCommitment.toBytes();
        console.logBytes(hookData);
        // vm.startPrank(_jitLp);

        // _liquidityTimeCommitmentRouter.modifyLiquidity(
        //     key,
        //     LIQUIDITY_PARAMS,
        //     hookData
        // );
        // // // Expected JIT lp position key
        // // bytes32 jitPositionKey = liquidityTimeCommitmentData.getPositionKey(
        // //     LIQUIDITY_PARAMS
        // // );

        // (uint256 amount0, uint256 amount1) = jitLiquidityManager
        //     .getClaimableLiquidityOnCurrencies(key);

        // // console.log("JIT Position Key:", uint256(jitPositionKey));
        // console.log(
        //     "Expected JIT Liquidity Manager: ",
        //     address(jitLiquidityManager)
        // );
        // // console.log(
        // //     "Actual JIT Liquidity Manager: ",
        // //     address(
        // //         liquidityTimeCommitmentHook.getLPLiquidityManager(
        // //             jitPositionKey,
        // //             LPType.JIT
        // //         )
        // //     )
        // // );
        // console.log("amount0: ", amount0);
        // console.log("amount1: ", amount1);
        // vm.stopPrank();

        // This call is unlocked by the poolManager
        // then it is supposed to send the
        // CallbackData with keys to the
        // hook
    }
}
