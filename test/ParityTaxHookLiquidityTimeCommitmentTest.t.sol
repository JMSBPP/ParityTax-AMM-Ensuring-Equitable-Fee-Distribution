// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../src/LiquidityTimeCommitmentManager.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import "v4-core/libraries/Position.sol";
import "../src/TaxController.sol";
import "../src/hooks/ParityTaxHook.sol";
import {JITHub} from "../src/JITUtils/JITHub.sol";

uint256 constant JULY_8TH_TIMESTAMP = 1752012003;
contract ParityTaxHookLiquidityTimeCommitmentTest is Test, Deployers {
    using Position for address;

    LiquidityTimeCommitmentManager liquidityTimeCommitmentManager;
    TaxController taxController;
    ParityTaxHook parityTaxHook;
    JITHub jitHub;

    bytes32 positionKey;

    // afterAddLiquidity: true
    // beforeRemoveLiquidity: true,
    // beforeSwap: true,
    // afterSwap: true
    // afterSwapReturnDelta: true
    // afterAddLiquidityReturnDelta: true,
    // afterRemoveLiquidityReturnDelta: true

    function setUp() public {
        vm.warp(JULY_8TH_TIMESTAMP);
        {
            deployFreshManagerAndRouters();
            deployMintAndApprove2Currencies();
        }
        {
            liquidityTimeCommitmentManager = new LiquidityTimeCommitmentManager(
                manager
            );
            taxController = new TaxController(
                manager,
                liquidityTimeCommitmentManager
            );
            jitHub = new JITHub(manager);
            parityTaxHook = ParityTaxHook(
                address(
                    uint160(
                        Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
                            Hooks.BEFORE_SWAP_FLAG |
                            Hooks.AFTER_SWAP_FLAG |
                            Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG |
                            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                            Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG |
                            Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
                            Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG
                    )
                )
            );

            deployCodeTo(
                "ParityTaxHook",
                abi.encode(manager, taxController, jitHub),
                address(parityTaxHook)
            );
        }
        {
            //NOTE: This code chunk starts a pool with empty liquidity
            (key, ) = initPool(
                currency0,
                currency1,
                IHooks(address(parityTaxHook)),
                3000,
                60,
                SQRT_PRICE_1_2
            );
        }
    }

    function test__AddLiquidityTimeCommiment() external {
        //NOTE: Let's start with a jit adding liquidity
        vm.warp(JULY_8TH_TIMESTAMP + 1);
        TimeCommitment jitTimeCommitment = toTimeCommitment(JIT_FLAG);
        {
            modifyLiquidityRouter.modifyLiquidity(
                key,
                LIQUIDITY_PARAMS,
                abi.encode(jitTimeCommitment)
            );
        }
        TimeCommitment plpTimeCommitment = toTimeCommitment(
            uint48(JULY_8TH_TIMESTAMP + 100)
        );
        {
            modifyLiquidityRouter.modifyLiquidity(
                key,
                LIQUIDITY_PARAMS,
                abi.encode(plpTimeCommitment)
            );
        }
    }
}
