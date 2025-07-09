// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//TODO: Candidate data structures for indexing swap data
// based on toxicity
// ============ DATA STRUCTRUES  =====================
import "openzeppelin/utils/structs/DoubleEndedQueue.sol";
import "openzeppelin/utils/structs/EnumerableMap.sol";
import "openzeppelin/utils/structs/EnumerableSet.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {ImmutableState} from "v4-periphery/src/base/ImmutableState.sol";

// =============UNISWAP OWN TYPES============================
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {PoolId} from "v4-core/types/PoolId.sol";

// ===================INTERFACES ================
import {IJITHub} from "./interfaces/IJITHub.sol";

// ================CUSTOM TYPES IMPORTS =======
import {ToxicityLevel, ToxicityLevelLibrary} from "./types/ToxicityLevel.sol";
import {SwapData, SwapDataLibrary} from "./types/SwapData.sol";
import {JITLiquidityDistributionOnSwap, JITLiquidityDistributionOnSwapLibrary} from "./types/JITLiquidityDistributionOnSwap.sol";

//NOTE: This contract is owned or administeed by the TaxController

contract JITHub is IJITHub, ImmutableState {
    mapping(PoolId poolId => mapping(ToxicityLevel toxicityLevel => SwapData))
        private _tradingVolumeClassifiedData;

    mapping(PoolId poolId => SwapData) private _tradingVolumeData;
    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    //NOTE: This function is called the ParityTaxHook
    function calculateJITLiquidityParamsForSwap(
        SwapParams memory swapParams
    )
        external
        returns (
            JITLiquidityDistributionOnSwap memory jitLiquidityDistributionOnSwap
        )
    {}

    // NOTE This function needs to have access control

    function pushSwapData(
        PoolId poolId,
        SwapParams memory enteredSwapParams
    ) private {
        _tradingVolumeData[poolId].poolSwaps.push(enteredSwapParams);
    }
}
