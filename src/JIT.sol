// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IPoolManager} from "@unsiwap/v4-core/rsc/interfaces/IPoolManager.sol";
import {StateView} from "@uniswap/v4-periphery/src/lens/StateView.sol";

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// This contract aims to be a calculator of JIT
// operations
abstract contract JIT is StateView, Initializable {
    constructor(IPoolManager _poolManager) StateView(_poolManager) {}

    function initialize(PoolKey key) public virtual initializer {
        
    }


}
