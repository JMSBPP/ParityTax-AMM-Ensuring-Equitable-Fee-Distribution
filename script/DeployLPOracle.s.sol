// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";
import "forge-std/Script.sol";

import {ILPOracle} from "../src/interfaces/ILPOracle.sol";
import {MockLPOracle} from "../test/mocks/MockLPOracle.sol";

contract DeployLPOracleScript is Script {
    function setUp() public {}

    function run() public returns (ILPOracle lpOracle) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);
        lpOracle = new MockLPOracle();
        vm.stopBroadcast();
    }
}   