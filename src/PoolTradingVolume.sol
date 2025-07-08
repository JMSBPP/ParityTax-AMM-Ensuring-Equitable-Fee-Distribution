// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//TODO: Candidate data structures for indexing swap data
// based on toxicity
import "openzeppelin/utils/structs/DoubleEndedQueue.sol";
import "openzeppelin/utils/structs/EnumerableMap.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";
import {ImmutableState} from "v4-periphery/src/base/ImmutableState.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {IJITHub} from "./JITUtils/interfaces/IJITHub.sol";
// IDEA: We want a data structure that indexes swapData
// based on a metric called toxicity
// Thus we need to define the metric

//NOTE: Does this data structure needs to have is own dedicated
// libraires
struct SwapData {
    SwapParams[] poolSwaps;
}
//TODO: This needs to be a dedicated type
type ToxicityLevel is uint8;
//NOTE: There is some bitMap job here to determine the toxicity level

// TODO: This contract needs to UPGRADE JITHubs

contract PoolTradingVolume is ImmutableState {
    //NOTE: Is this contract going to do callbacks to be
    // unlocked ?
    mapping(PoolId poolId => mapping(ToxicityLevel toxicityLevel => SwapData))
        private _tradingVolumeData;

    // NOTE: Is this iterable? What other properties it has ?
    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    function setLiquidityParamsForSwap(
        SwapParams memory swapParams,
        IJITHub jitHub
    )
        external
        view
        returns (ModifyLiquidityParams memory jitLiquidityParamsOnSwap)
    {}
}
