// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "./interfaces/ILiquidityTimeCommitmentStateQuerier.sol";
// TODO: Ideally we want to apply proxy patterns here to query
// but this is done later.

// This is we want the data contract as (LiquidityTimeCommitmentState)
// and the most convenient implementation to update
// state variables
contract LiquidityTimeCommitmentState is ILiquidityTimeCommitmentStateQuerier {
    using TimeCommitmentLibrary for TimeCommitment;

    mapping(PoolId poolId => mapping(bytes32 positionKey => TimeCommitment timeCommitment))
        internal timeCommitments;

    mapping(PoolId poolId => bytes32[] positions) internal poolPositions;

    function getCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) public view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = timeCommitments[poolId][positionKey];
    }

    function getPoolCommitments(
        PoolId poolId
    ) public view returns (IndexedTimeCommitments[] memory) {
        IndexedTimeCommitments[]
            memory tempIndexedTimeCommitmentsArray = new IndexedTimeCommitments[](
                poolPositions[poolId].length
            );

        for (
            uint256 positionIndex = 0;
            positionIndex < poolPositions[poolId].length;
            positionIndex++
        ) {
            tempIndexedTimeCommitmentsArray[
                positionIndex
            ] = IndexedTimeCommitments({
                positionKey: poolPositions[poolId][positionIndex],
                timeCommitment: timeCommitments[poolId][
                    poolPositions[poolId][positionIndex]
                ]
            });
        }
        return tempIndexedTimeCommitmentsArray;
    }

    function getPoolExpiredCommitments(
        PoolId poolId
    ) public view returns (IndexedTimeCommitments[] memory) {
        // Get the length of the array
        uint256 length;
        for (
            uint256 positionIndex = 0;
            positionIndex < poolPositions[poolId].length;
            positionIndex++
        ) {
            bytes32 position = poolPositions[poolId][positionIndex];
            TimeCommitment memory timeCommitment = timeCommitments[poolId][
                position
            ];

            if (block.number < timeCommitment.getExpirationBlock()) {
                length++;
            }
        }

        IndexedTimeCommitments[]
            memory tempIndexedTimeCommitmentsArray = new IndexedTimeCommitments[](
                length
            );
        for (
            uint256 positionIndex = 0;
            positionIndex < poolPositions[poolId].length;
            positionIndex++
        ) {
            bytes32 position = poolPositions[poolId][positionIndex];
            TimeCommitment memory timeCommitment = timeCommitments[poolId][
                position
            ];

            if (block.number < timeCommitment.getExpirationBlock()) {
                tempIndexedTimeCommitmentsArray[
                    positionIndex
                ] = IndexedTimeCommitments({
                    positionKey: position,
                    timeCommitment: timeCommitment
                });
            }
        }
        return tempIndexedTimeCommitmentsArray;
    }
}
