// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolId, PoolKey, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

interface IPLPResolver{
    
    error InvalidCommitment___MustBeGreaterThanCurrentBlock();
    
    function commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        uint48 blockNumber
    ) external returns(uint256);


    function removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) external;


}