// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../src/LiquidityTimeCommitmentManager.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import "v4-core/libraries/Position.sol";
import "../src/TaxController.sol";
import "permit2/src/AllowanceTransfer.sol";

contract ParityTaxHookLiquidityTimeCommitmentTest is Test, Deployers {
    using Position for address;

    LiquidityTimeCommitmentManager liquidityTimeCommitmentManager;
    TaxController taxController;
    ParityTaxHook parityTaxHook;
    AllowanceTransfer permit2;

    bytes32 positionKey;

    // afterAddLiquidity: true
    // beforeRemoveLiquidity: true,
    // beforeSwap: true,
    // afterSwap: true
    // afterSwapReturnDelta: true
    // afterAddLiquidityReturnDelta: true,
    // afterRemoveLiquidityReturnDelta: true
    function setUp() public {
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
            permit2 = new AllowanceTransfer();
            parityTaxHook = ParityTaxHook(
                payable(
                    address(
                        uint160(
                            (type(uint160).max & clearAllHookPermissionsMask) |
                                Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                                Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
                                Hooks.BEFORE_SWAP_FLAG |
                                Hooks.AFTER_SWAP_FLAG |
                                Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG |
                                Hooks.AFTER_ADD_LIQUIDITY_RETURN_DELTA_FLAG |
                                Hooks.AFTER_REMOVE_LIQUIDITY_RETURN_DELTA_FLAG
                        )
                    )
                )
            );
            deployCodeTo(
                type(ParityTaxHook).creationCode,
                abi.encode(manager, permit2, taxController),
                address(parityTaxHook)
            );
        }
    }

    //NOTE: To test without the hook we need to set a timeCommitment here,
    // In practice timeCommitments will be set on the hook
    // function test__updatePositionTimeCommitment() external {}
}
