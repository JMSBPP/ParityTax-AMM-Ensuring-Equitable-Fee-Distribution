// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LiquidityTimeCommitmentManager} from "../../src/LiquidityTimeCommitmentManager.sol";
import {TaxController} from "../../src/TaxController.sol";
import {ParityTaxHook} from "../../src/hooks/ParityTaxHook.sol";
import {JITHub} from "../../src/JITUtils/JITHub.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

contract SharedStateSetUp is Test, Deployers {
    LiquidityTimeCommitmentManager internal liquidityTimeCommitmentManager;
    TaxController internal taxController;
    ParityTaxHook internal parityTaxHook;
    JITHub internal jitHub;

    function deployBaseProtocol(uint256 blockTimeStamp) internal virtual {
        vm.warp(blockTimeStamp);
        {
            deployFreshManagerAndRouters();
            (currency0, currency1) = deployMintAndApprove2Currencies();
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
    }
}
