// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";


contract MockPLPResolver is IPLPResolver{

    function commitLiquidity(
        PoolId poolId,
        bytes32 positionKey,
        uint48 blockNumber
    ) external{

    }

    function getPLPCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns(uint48){

    }

}