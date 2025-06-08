// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolId.sol";
import "../types/TimeCommitment.sol";

struct IndexedTimeCommitments {
    bytes32 positionKey;
    TimeCommitment timeCommitment;
}

interface ILiquidityTimeCommitmentStateQuerier {
    function getCommitment(
        PoolId poolId,
        bytes32 positionKey
    ) external view returns (TimeCommitment memory);

    function getPoolCommitments(
        PoolId poolI
    ) external view returns (IndexedTimeCommitments[] memory);

    function getPoolExpiredCommitments(
        PoolId poolId
    ) external view returns (IndexedTimeCommitments[] memory);

    // function getPoolCommitmentsOnBlock(
    //     PoolId poolId,
    //     uint256 startingBlock
    // )
    //     external
    //     view
    //     returns (IndexedTimeCommitments[] memory indexedOnBlockTimeCommitments);

    // function getPoolCommitmentsOnBlockWithDuration(
    //     PoolId poolId,
    //     uint256 startingBlock,
    //     uint256 duration
    // )
    //     external
    //     view
    //     returns (
    //         IndexedTimeCommitments[]
    //             memory indexedOnBlockWithDurationTimeCommitments
    //     );
}
