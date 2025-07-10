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
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
//NOTE: This contract is owned or administeed by the TaxController

contract JITHub is IJITHub, ImmutableState {
    using StateLibrary for IPoolManager;
    mapping(PoolId poolId => mapping(ToxicityLevel toxicityLevel => SwapData))
        private _tradingVolumeClassifiedData;

    mapping(PoolId poolId => SwapData) private _tradingVolumeData;
    constructor(IPoolManager _manager) ImmutableState(_manager) {}

    //NOTE: This function is called the ParityTaxHook
    // This is a feature to intgrate with Bunni to be considered on future
    // iterations
    function calculateJITLiquidityParamsForSwap(
        SwapParams memory swapParams
    )
        external
        returns (
            JITLiquidityDistributionOnSwap memory jitLiquidityDistributionOnSwap
        )
    {}

    // TODO: From now as shown on ./spec/Ref2.sol The JIT conditions for profitability is
    // not dependant on the level of liquidity provided on a certain tick-range for a given swap
    // bt depends on the price impact and on the trading fee
    // IDEA: This means that dynamic fee can be designed to incentivize JIT's on certain assets
    function isJITProfitable(
        PoolId poolId,
        SwapParams memory swapParams
    ) external view returns (bool) {
        // TODO: We need to get the price impact this is the
        // distance between the price before excecution and the price after excecution
        // 1. Retrieve the current price
        (
            uint160 currentPriceX96,
            int24 currentTickPrice,
            uint24 protocolFee,
            uint24 swapFee
        ) = poolManager.getSlot0(poolId);
        //  TODO: This naive apporoache is to be replaced for a more accurate one
        // becuase this normally is specified at the highest priceImpact, becaus it is unlikely
    }

    // NOTE This function needs to have access control

    function pushSwapData(
        PoolId poolId,
        SwapParams memory enteredSwapParams
    ) private {
        _tradingVolumeData[poolId].poolSwaps.push(enteredSwapParams);
    }
}
