// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";

import "../utils/LiquidityTimeCommitmentRouterTestSetUp.sol";
import "../../src/hooks/LiquidityTimeCommitmentHook.sol";
contract LiquidityTimeCommitmentHookForkTest is
    Test,
    LiquidityTimeCommitmentRouterTestSetup
{
    bool forked;

    LiquidityTimeCommitmentHook public liquidityTimeCommitmentHook;
    address plpProvider = makeAddr("PLP");
    address jitProvider = makeAddr("JIT");

    function setUp() public {
        try vm.envString("UNICHAIN_SEPOLIA_RPC_API_KEY") returns (
            string memory
        ) {
            console2.log("Forked Unichain Sepolia");

            vm.createSelectFork(vm.rpcUrl("unichain-sepolia"), 23_311_526);
            _deployLiquidityTimeCommitmentRouter();
            _deployMintAndApproveToLiquiditTimeCommitmentRouter2Currencies();
            console.log(
                "Circulating Supply Currency 0:",
                currency0.balanceOfSelf()
            );
            console.log(
                "Circulating Supply Currency 1:",
                currency1.balanceOfSelf()
            );
            currency0.transfer(plpProvider, 1000e18);
            currency1.transfer(plpProvider, 1000e18);

            currency0.transfer(jitProvider, 1000e18);
            currency1.transfer(jitProvider, 1000e18);
            liquidityTimeCommitmentHook = LiquidityTimeCommitmentHook(
                payable(
                    address(
                        uint160(
                            (type(uint160).max & clearAllHookPermissionsMask) |
                                Hooks.BEFORE_SWAP_FLAG |
                                Hooks.AFTER_SWAP_FLAG |
                                Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
                                Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                                Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG |
                                Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
                        )
                    )
                )
            );
            deployCodeTo(
                "LiquidityTimeCommitmentHook",
                abi.encode(address(manager)),
                address(liquidityTimeCommitmentHook)
            );
        } catch {
            console2.log("Not forked Unichain Sepolia, not API key provider");
        }
    }
}
