// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";


import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IParityTaxHook} from "../src/interfaces/IParityTaxHook.sol";
import {IPLPResolver} from "../src/interfaces/IPLPResolver.sol";
import {IJITResolver} from "../src/interfaces/IJITResolver.sol";


//NOTE: Update this to the Resolvers you are using
import {MockJITResolver} from "../test/mocks/MockJITResolver.sol";
import {MockPLPResolver} from "../test/mocks/MockPLPResolver.sol";


contract DeployLiquidityResolversScript is Script {
    function setUp() public {}

// deployAndApproveResolvers(manager,lpm, parityTaxHook);

    function run(
        address poolManager,
        address lpm,
        address parityTaxHook
    ) public returns (MockJITResolver jitResolver, MockPLPResolver plpResolver) {

        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);

        jitResolver = new MockJITResolver(
            IPoolManager(poolManager),
            IPositionManager(lpm),
            IParityTaxHook(parityTaxHook)
        );
        plpResolver = new MockPLPResolver(
            IPoolManager(poolManager),
            IPositionManager(lpm),
            IParityTaxHook(parityTaxHook)
        );

        vm.stopBroadcast();

        return (jitResolver, plpResolver);
    }

    function approvePosmForResolvers(
        Currency currency0,
        Currency currency1,
        address jitResolver,
        address plpResolver,
        address permit2
    ) public returns (uint256 deployerBalanceOnCurrency0, uint256 deployerBalanceOnCurrency1) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployerAddress = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        address token0 = Currency.unwrap(currency0);
        address token1 = Currency.unwrap(currency1);
        deployerBalanceOnCurrency0 = IERC20(token0).balanceOf(deployerAddress);
        deployerBalanceOnCurrency1 = IERC20(token1).balanceOf(deployerAddress);
        IERC20(token0).approve(address(permit2), deployerBalanceOnCurrency0);        
        IERC20(token1).approve(address(permit2), deployerBalanceOnCurrency1);
        IERC20(token0).approve(address(jitResolver), deployerBalanceOnCurrency0);
        IERC20(token1).approve(address(jitResolver), deployerBalanceOnCurrency1);
        IERC20(token0).approve(address(plpResolver), deployerBalanceOnCurrency0);
        IERC20(token1).approve(address(plpResolver), deployerBalanceOnCurrency1);
        vm.stopBroadcast();

        console2.log("Deployer balance on currency0", deployerBalanceOnCurrency0);
        console2.log("Deployer balance on currency1", deployerBalanceOnCurrency1);

        return (deployerBalanceOnCurrency0, deployerBalanceOnCurrency1);
    }

    function fundResolvers(
        address token0,
        address token1,
        address jitResolver,
        address plpResolver,
        uint256 amount0,
        uint256 amount1
    ) public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        IERC20(token0).transfer(address(jitResolver), amount0);
        IERC20(token1).transfer(address(jitResolver), amount1);
        IERC20(token0).transfer(address(plpResolver), amount0);
        IERC20(token1).transfer(address(plpResolver), amount1);
        vm.stopBroadcast();
    }
    
    function setLiquidityResolvers(
        address parityTaxHook,
        address jitResolver,
        address plpResolver
    ) public {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);
        IParityTaxHook(parityTaxHook).setLiquidityResolvers(IPLPResolver(plpResolver), IJITResolver(jitResolver));
        vm.stopBroadcast();
    
    }
}




