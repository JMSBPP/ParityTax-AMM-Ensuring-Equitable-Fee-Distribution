// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {IFiscalPolicy} from "../src/interfaces/IFiscalPolicy.sol";

import "forge-std/console2.sol";

//NOTE: Update this to the Fiscal Policy you are using
import {UniformFiscalPolicy} from "../test/mocks/UniformFiscalPolicy.sol";

import {IParityTaxHook} from "../src/interfaces/IParityTaxHook.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {ILPOracle} from "../src/interfaces/ILPOracle.sol";


import {ParityTaxRouter} from "../src/ParityTaxRouter.sol";
import {IV4Quoter} from "@uniswap/v4-periphery/src/interfaces/IV4Quoter.sol";
import {IParityTaxRouter} from "../src/interfaces/IParityTaxRouter.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


contract DeployFiscalPolicyScript is Script {
    function setUp() public {}

    function run(
        address callbackSender,
        address manager,
        address lpOracle,
        address lpm,
        address parityTaxHook,
        address v4Quoter
    ) public returns (UniformFiscalPolicy fiscalPolicy, ParityTaxRouter parityTaxRouter) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);
        fiscalPolicy = new UniformFiscalPolicy(callbackSender, ILPOracle(lpOracle), IPositionManager(lpm), IParityTaxHook(parityTaxHook));
        parityTaxRouter = new ParityTaxRouter(IPoolManager(manager), IV4Quoter(v4Quoter), IParityTaxHook(parityTaxHook));
        vm.stopBroadcast(); 
    }

    function approveRouter(
        address permit2,
        Currency currency0,
        Currency currency1,
        address parityTaxRouter
    ) public returns (uint256 deployerBalanceOnCurrency0, uint256 deployerBalanceOnCurrency1) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        deployerBalanceOnCurrency0 = IERC20(Currency.unwrap(currency0)).balanceOf(deployerAddress);
        deployerBalanceOnCurrency1 = IERC20(Currency.unwrap(currency1)).balanceOf(deployerAddress);
        IERC20(Currency.unwrap(currency0)).approve(address(parityTaxRouter), deployerBalanceOnCurrency0);
        IERC20(Currency.unwrap(currency1)).approve(address(parityTaxRouter), deployerBalanceOnCurrency1);
        IERC20(Currency.unwrap(currency0)).approve(address(permit2), deployerBalanceOnCurrency0);
        IERC20(Currency.unwrap(currency1)).approve(address(permit2), deployerBalanceOnCurrency1);
        vm.stopBroadcast();

        console2.log("Deployer balance on currency0", deployerBalanceOnCurrency0);
        console2.log("Deployer balance on currency1", deployerBalanceOnCurrency1);

        return (deployerBalanceOnCurrency0, deployerBalanceOnCurrency1);
    }
}

