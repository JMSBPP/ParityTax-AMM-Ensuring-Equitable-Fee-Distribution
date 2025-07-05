// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../src/LiquidityTimeCommitmentManager.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import "v4-core/libraries/Position.sol";
import "../src/TaxController.sol";
import "../src/hooks/ParityTaxHook.sol";

contract ParityTaxHookLiquidityTimeCommitmentTest is Test, Deployers {
    using Position for address;

    LiquidityTimeCommitmentManager liquidityTimeCommitmentManager;
    TaxController taxController;
    ParityTaxHook parityTaxHook;

    bytes32 positionKey;

    // afterAddLiquidity: true
    // beforeRemoveLiquidity: true,
    // beforeSwap: true,
    // afterSwap: true
    // afterSwapReturnDelta: true
    // afterAddLiquidityReturnDelta: true,
    // afterRemoveLiquidityReturnDelta: true
    address jit = makeAddr("jit");
    address plp = makeAddr("plp");
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
                abi.encode(manager, taxController),
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
        vm.startPrank(jit);
        //NOTE: It is going to call the modifyLiquidityRouter
        // to add Liquidity with a valid jitCommitment
        TimeCommitment jitTimeCommitment = toTimeCommitment(JIT_FLAG);
        console2.log(uint256(TimeCommitment.unwrap(jitTimeCommitment)));
        {
            modifyLiquidityRouter.modifyLiquidity(
                key,
                LIQUIDITY_PARAMS,
                abi.encode(jitTimeCommitment)
            );
            // NOTE: The call will:
            // router.modifyLiquidity()
            //   -> manager.unlock() -> router.unlockCallback()
            //   -> manager.modifyLiquidity()
            //   - (event ModifyLiquidity)
            //   -> ParityTaxHook.afterAddLiqudity()
            //    -> TaxController.updateTaxAccount()
            //     -> liquidityTimeCommitmentManager.updateTaxAccount()
            //      -> (event PositionTimeCommitmentUpdated(
            //                        poolId,
            //                        positionKey,
            //                        JIT_FLAG
            //                        liquidity
            //                        ))
            // Liquidity will be added to the pool
            //
        }
    }
}
