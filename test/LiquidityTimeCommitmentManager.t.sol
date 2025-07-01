// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import "../src/LiquidityTimeCommitmentManager.sol";
import "@uniswap/test/utils/Deployers.sol";
import "v4-core/libraries/Position.sol";
contract TimeCommitmentTest is Test, Deployers {
    using Position for address;

    LiquidityTimeCommitmentManager liquidityTimeCommitmentManager;
    bytes32 positionKey;
    function setUp() public {
        initializeManagerRoutersAndPoolsWithLiq(IHooks(address(0)));
        //Here the owner is address(nestedActionRouter)
        liquidityTimeCommitmentManager = new LiquidityTimeCommitmentManager(
            manager
        );
        positionKey = address(nestedActionRouter).calculatePositionKey(
            LIQUIDITY_PARAMS.tickLower,
            LIQUIDITY_PARAMS.tickUpper,
            LIQUIDITY_PARAMS.salt
        );
    }

    //NOTE: To test without the hook we need to set a timeCommitment here,
    // In practice timeCommitments will be set on the hook
    function test__updatePositionTimeCommitment() external {}
}
