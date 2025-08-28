//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
// import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

interface IJITHub{

    function approveJITLiquidityForSwap(
        PoolKey memory pooKey,
        ModifyLiquidityParams memory jitLiquidityParams
    ) external returns (uint256 liquidity0, uint256 liquidity1);
}