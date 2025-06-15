// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//====================CONTRACTS TO BE TESTED ==============
import "../../src/hooks/LiquidityTimeCommitmentClassifier.sol";
import "../../src/LiquidityTimeCommitmentManager.sol";
import "../../src/hooks/LiquidityOperator.sol";

//========================TEST-UTILS =======================

import {Test, console} from "forge-std/Test.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";
import "../utils/LiquidityTimeCommitmentRouterTestSetUp.sol";
import "../../src/hooks/JITLiquidityOperator.sol";
import "../../src/hooks/PLPLiquidityOperator.sol";
import "../../src/hooks/mining/JITHookMiner.sol";
import "../../src/LiquidityTimeCommitmentManager.sol";
import "../../src/hooks/LiquidityTimeCommitmentClassifier.sol";
import "../../src/hooks/mining/PLPHookMiner.sol";

contract DirectLiquidityTest is Test, LiquidityTimeCommitmentRouterTestSetup {
    using JITHookMiner for address;
    using JITHookMiner for IPoolManager;
    using PLPHookMiner for address;
    using PLPHookMiner for IPoolManager;
    // 0. We need initally a couple of addresses one representing
    // A PLP and another representing a JIT
    address internal _plpLp = makeAddr("PLP");
    address internal _jitLp = makeAddr("JIT");

    //========CONTRACTS TO BE TESTED =============================
    // =========PERIPHERY =====================
    LiquidityTimeCommitmentManager internal _liquidityTimeCommitmentManager;
    //===========HOOKS========================
    LiquidityTimeCommitmentClassifier
        internal _liquidityTimeCommitmentClassifier;
    JITLiquidityOperator internal _jitLiquidityOperator;
    PLPLiquidityOperator internal _plpLiquidityOperator;

    function setUp() public {
        // TODO:

        // 1. We need to deploy the poolManager
        deployFreshManager();

        // 2. We need to deploy2currencies and deploy and approve the
        // liquidityTimeCommitmentRouter
        _deployMintAndApproveToLiquiditTimeCommitmentRouter2Currencies();
        // 3. We need to provide tokens to the providers, so they can interact with the pool
        currency0.transfer(_plpLp, 1000e18);
        currency1.transfer(_jitLp, 1000e18);

        // 4. Before deploying the pool
        // 4.1 Deploy and approve the position Manager
        deployAndApprovePosm(manager);
        // NOTE: referred as lpm with allowance to manager 2**256 amount
        // of each token
        // 5 We now can deploy the LiquidityTimeCommitmentManager
        bytes memory liquidityTimeCommitmentManagerConstructorArgs = abi.encode(
            manager,
            lpm
        );
        //Add all the necessary constructor arguments from the hook

        // From PosmTestSetUp we have a governance address
        // Let this address be the authorized deployer of routers
        // Which makes sense on a real-world deployment
        vm.startPrank(governance);

        bytes memory liquidityTimeCommitmentManagerBytecode = abi.encodePacked(
            type(LiquidityTimeCommitmentRouter).creationCode,
            liquidityTimeCommitmentManagerConstructorArgs
        );

        address predictedLiquidityTimeCommitmentManagerAddress = vm
            .computeCreate2Address(
                bytes32(0), //NOTE: No salt, QUESTION why needed?
                keccak256(liquidityTimeCommitmentManagerBytecode),
                governance
            );

        vm.stopPrank();

        deployCodeTo(
            "../../src/LiquidityTimeCommitmentManager.sol:LiquidityTimeCommitmentManager",
            liquidityTimeCommitmentManagerConstructorArgs,
            predictedLiquidityTimeCommitmentManagerAddress
        );

        _liquidityTimeCommitmentManager = LiquidityTimeCommitmentManager(
            predictedLiquidityTimeCommitmentManagerAddress
        );
        // The Custom Router that considers the LiquidityTimeCommitmentCallbackData
        // is finally deployed
        // 6. With router, positionManager, poolManager out of the way
        // we need to deploy the LiquidityTimeCommitmentClassifier
        // and operators

        // 6.1 Since the operators are hooks, and therefore we need to do
        // address minining to avoid collisions, we proceed first with the
        // their deployment.
        // 6.1.1 JITLiquidityOperator Hook
        (address jitLiquidityOperatorAddress, ) = manager
            ._getJITOperatorHookAddressAndSalt(governance);

        // Deploy the JIT Liquidity Operator contract
        _jitLiquidityOperator = JITLiquidityOperator(
            jitLiquidityOperatorAddress
        );

        // 6.1.2 PLPLiquidityOperator Hook
        // Now we need
        (address plpLiquidityOperatorAddress, ) = manager
            ._getPLPOperatorHookAddressAndSalt(governance);

        // Deploy the PLP Liquidity Operator contract
        _plpLiquidityOperator = PLPLiquidityOperator(
            plpLiquidityOperatorAddress
        );

        //We need to deploy the liquidityTimeCommitmenetClassifier
        // since this is other hook attahed to the pool ...

        //6.2 Mine valid addresses for the liquidityTimeCommitmetClassifier
    }
}
