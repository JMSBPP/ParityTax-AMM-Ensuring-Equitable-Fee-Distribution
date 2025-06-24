// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../types/LPTimeCommitmentTest.sol";
import "./LPTimeCommitmentDeployers.sol";
contract LPTimeCommmitmentSetUp is Test, LPTimeCommitmentDeployers {
    OperatorAddresses operatorAddresses;

    //=========WRAPPED LIBRARY TO BE TESTED =========
    LPTimeCommitmentTest public lpTimeCommitmentLibrary;
    //NOTE At this point all not hook contracts should have
    // been deployed ...
    address payable jit = payable(makeAddr("jit"));
    address payable plp = payable(makeAddr("plp"));

    function setUp() public virtual {
        operatorAddresses = setOperatorsAddresses();
        // Deploy WETH hook
        jitHook = JITHook(operatorAddresses.jitHook);

        deployCodeTo(
            "JITHook",
            getOperatorsConstructorArgs(),
            operatorAddresses.jitHook
        );
        plpOperator = PLPLiquidityOperator(operatorAddresses.plpOperator);

        deployCodeTo(
            "PLPLiquidityOperator",
            getOperatorsConstructorArgs(),
            operatorAddresses.plpOperator
        );

        invalidOperator = InvalidOperator(operatorAddresses.invalidOperator);
        deployCodeTo(
            "InvalidOperator",
            getOperatorsConstructorArgs(),
            operatorAddresses.invalidOperator
        );

        //NOTE: ALl hooks and dependencies are deployed ...
        lpTimeCommitmentLibrary = new LPTimeCommitmentTest();

        liquidityTimeCommitmentHook = LiquidityTimeCommitmentHook(
            getLiquidityTimeCommitmentHookAddress()
        );
        deployCodeTo(
            "LiquidityTimeCommitmentHook",
            abi.encode(manager),
            getLiquidityTimeCommitmentHookAddress()
        );
    }
}
