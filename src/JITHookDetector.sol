// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC165Checker} from "permit2/lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import {ERC165Storage} from "permit2/lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Storage.sol";
import {IJIT} from "./interfaces/IJIT.sol";

//Verifiies if the hook is a valid standard JIT Hooks, this allows the subscription
// to filter through the noise of JIT Hooks worngly implemented or
// contracts that re not even hooks

contract JITHookDetector is ERC165Storage {
    using ERC165Checker for address;
    function isJITHook(address jitHook) external view returns (bool) {
        return jitHook.supportsInterface(type(IJIT).interfaceId);
    }
}
