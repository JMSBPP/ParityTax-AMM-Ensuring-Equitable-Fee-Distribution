// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IPLPOperator} from ".../../src/interfaces/IPLPOperator.sol";
import "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract MockPLPOperator is LiquidityOperations, ImmutableState, IPLPOperator{

    mapping(PoolId poolId => mapping(bytes32 positionKey => uint48 blockNumber)) private plpCommitment;


    constructor(IPoolManager _manager) ImmutableState(_manager){}

    // TODO: This commitment is to give staking rewards
    // TODO: This function is guarded
    function commitLiquidity(
        PoolId poolId,
        bytes32 positionKey,
        uint48 blockNumber
    ) external {
        if (blockNumber <= block.number) revert InvalidCommitment___MustBeGreaterThanCurrentBlock();
        plpCommitment[poolId][positionKey] = blockNumber;
    }

    function getPLPCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns(uint48){
        return plpCommitment[poolId][positionKey];
    }

}


