// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../src/TradingFeeRevenueDB.sol";
import "../../../src/TaxController.sol";

import "./LPTimeCommitmentConstants.sol";
import "@uniswap/v4-core/test/utils/Deployers.sol";

import "v4-periphery/src/utils/HookMiner.sol";

struct OperatorAddresses {
    address jitHook;
    address plpOperator;
    address invalidOperator;
}

contract LPTimeCommitmentDeployers is Test, Deployers {
    using HookMiner for address;
    using OperatorsDeployersDataLibrary for OPERATOR_TYPE;

    JITHook jitHook;
    PLPLiquidityOperator plpOperator;
    InvalidOperator invalidOperator;
    ITradingFeeRevenueDB tradingFeeRevenueDB;
    ITaxController taxController;

    function deployTradingFeeRevenueDB() internal {
        tradingFeeRevenueDB = new TradingFeeRevenueDB();
    }

    function deployTaxController() internal {
        taxController = new TaxController();
    }

    function getOperatorsConstructorArgs() internal returns (bytes memory) {
        {
            deployFreshManager();
            deployTradingFeeRevenueDB();
            deployTaxController();
        }
        return abi.encode(manager, tradingFeeRevenueDB, taxController);
    }
    function setOperatorSaltAndAddress(
        OPERATOR_TYPE _operatorType
    ) internal returns (address operatorAddress) {
        (operatorAddress, ) = address(this).find(
            _operatorType.setOperatorFlags(),
            _operatorType.setOperatorCreationCode(),
            getOperatorsConstructorArgs()
        );
    }
    function setOperatorsAddresses()
        internal
        returns (OperatorAddresses memory operatorAddresses)
    {
        operatorAddresses = OperatorAddresses({
            jitHook: setOperatorSaltAndAddress(OPERATOR_TYPE.JIT),
            plpOperator: setOperatorSaltAndAddress(OPERATOR_TYPE.PLP),
            invalidOperator: setOperatorSaltAndAddress(OPERATOR_TYPE.INVALID)
        });
    }
    // TODO: Who is going to deploy this contracts -> address(this)

    //TODO:
    // 1. Create a valid JITHook address
    // 2. Create a valid PLPOperator address
    // 3. Create a valid Operator address not JIT, nor PLP
}
