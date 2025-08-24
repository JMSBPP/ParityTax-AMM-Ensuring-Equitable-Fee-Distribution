// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
interface IJITOperator{
    
    event AddJITLiquidity (
        PoolId indexed poolId,
        address indexed recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 addLiquidityDelta   
    ) anonymous; // Masrk anonymous so we can have more indexed arg
    // to fully identify the position 


    function addJITLiquidity(
        PoolKey calldata poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint128 addLiquidityDelta,
        address recipient,
        bytes calldata hookData
        
    ) external;

    function removeJITLiquidity(
        bytes32 jitPositionKey,
        bytes calldata hookData
    ) external;
}