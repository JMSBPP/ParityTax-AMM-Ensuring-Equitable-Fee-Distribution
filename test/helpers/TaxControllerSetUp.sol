// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {MockLPOracle} from "../mocks/MockLPOracle.sol";
import {LumpSumTaxController} from "../mocks/LumpSumTaxController.sol";
import {ParityTaxRouter} from "../../src/ParityTaxRouter.sol";
import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";
import {V4Quoter} from "@uniswap/v4-periphery/src/lens/V4Quoter.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

contract TaxControllerSetUp is Deployers {

    MockLPOracle lpOracle;
    LumpSumTaxController taxController;
    ParityTaxRouter parityTaxRouter;
    V4Quoter v4Quoter;

    function deployAndApproveTaxController(
        IPoolManager _manager
    ) internal{
        
        v4Quoter = new V4Quoter(
            _manager
        );

        parityTaxRouter = new ParityTaxRouter(
            _manager,
            IV4Quoter(address(v4Quoter))
        );

        lpOracle = new MockLPOracle();

        taxController = new LumpSumTaxController(
            lpOracle,
            parityTaxRouter
        );

        IERC20(Currency.unwrap(currency0)).approve(
            address(parityTaxRouter),
            Constants.MAX_UINT256
        );
        IERC20(Currency.unwrap(currency1)).approve(
            address(parityTaxRouter),
            Constants.MAX_UINT256
        );

   }

}