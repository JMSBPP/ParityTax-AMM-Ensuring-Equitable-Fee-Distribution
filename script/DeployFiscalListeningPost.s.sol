// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IParityTaxHook} from "../src/interfaces/IParityTaxHook.sol";
import {IFiscalPolicy} from "../src/interfaces/IFiscalPolicy.sol";

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import {FiscalListeningPost} from "../src/FiscalListeningPost.sol";

contract DeployFiscalListeningPostScript is Script {
    function setUp() public {}


    function run(
        uint256 chainId,
        address parityTaxHook,
        address fiscalPolicy
    ) public returns (FiscalListeningPost fiscalListeningPost) {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);
        fiscalListeningPost = new FiscalListeningPost(chainId, IParityTaxHook(parityTaxHook), IFiscalPolicy(fiscalPolicy));
        vm.stopBroadcast();

        return fiscalListeningPost;
    }
    
    
}

