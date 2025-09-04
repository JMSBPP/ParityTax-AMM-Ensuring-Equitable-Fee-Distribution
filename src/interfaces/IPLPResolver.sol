// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";


interface IPLPResolver{
    
    error InvalidCommitment___MustBeGreaterThanCurrentBlock();
    
    function commitLiquidity(
        PoolId poolId,
        bytes32 positionKey,
        uint48 blockNumber
    ) external;

    function getPLPCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns(uint48);


}