// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {ILPOracle} from "../src/interfaces/ILPOracle.sol";

import {
    IParityTaxHook,
    ParityTaxHook
} from "../src/ParityTaxHook.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

contract DeployParityTaxHookScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function setUp() public {}

    function run(
        address poolManager,
        address lpm,
        address lpOracle
    ) public returns (IParityTaxHook parityTaxHook) {

        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));


        uint160 flags = uint160(        
            Hooks.BEFORE_INITIALIZE_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.AFTER_ADD_LIQUIDITY_FLAG | Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG| 
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | Hooks.AFTER_REMOVE_LIQUIDITY_FLAG | 
            Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG | Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_DONATE_FLAG
        );

        bytes memory constructorArgs = abi.encode(
            IPoolManager(poolManager), IPositionManager(lpm), ILPOracle(lpOracle)
        );

        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(ParityTaxHook).creationCode, constructorArgs);

        vm.startBroadcast(deployerPrivateKey);

        parityTaxHook = new ParityTaxHook{salt: salt}(IPoolManager(poolManager), IPositionManager(lpm), ILPOracle(lpOracle));
        require(address(parityTaxHook) == hookAddress, "ParityTaxHookScript: hook address mismatch");

        vm.stopBroadcast();

        return parityTaxHook;
    }

    function getPoolKey(
        address poolManager,
        address token0,
        address token1,
        IParityTaxHook parityTaxHook
    ) public returns (PoolKey memory poolKey) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

        vm.startBroadcast(deployerPrivateKey);


    }

}
