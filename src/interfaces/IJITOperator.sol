// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

interface IJITOperator{
    
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