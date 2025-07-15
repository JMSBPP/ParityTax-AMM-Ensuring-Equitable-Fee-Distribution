// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../src/LiquidityTimeCommitmentManager.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import "v4-core/libraries/Position.sol";
import "../src/TaxController.sol";
import "../src/hooks/ParityTaxHook.sol";
import {JITHub} from "../src/JITUtils/JITHub.sol";

import {SharedStateSetUp} from "./shared/SharedStateSetUp.sol";
uint256 constant JULY_8TH_TIMESTAMP = 1752012003;
contract ParityTaxHookLiquidityTimeCommitmentTest is
    Test,
    Deployers,
    SharedStateSetUp
{
    using Position for address;

    bytes32 positionKey;

    function setUp() public {
        deployBaseProtocol(JULY_8TH_TIMESTAMP);
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

    function test__beforeSwapJITLiquidity() external {}
}
