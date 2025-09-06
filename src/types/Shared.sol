//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

uint48 constant JIT_COMMITMNET = uint48(0x01);
uint48 constant  MIN_PLP_BLOCK_NUMBER_COMMITMENT = uint48(0x02);
uint256 constant SWAP_CALLBACK_DATA_LENGTH = uint256(0x380);

struct JITData {
    PoolKey poolKey;                  // slot 0 (32B)
    int256 amountSpecified;                 // slot 1 (32B)
    uint256 amountIn;                       // slot 2 (32B)
    uint256 amountOut;                      // slot 3 (32B)

    // Pack addresses with uint160
    address token0;                         // 20B
    uint160 sqrtPriceLimitX96;              // 20B → shares with token0
    // total: 40B → spans slot 4 + slot 5

    address token1;                         // 20B
    uint160 beforeSwapSqrtPriceX96;         // 20B
    // total: 40B → spans slot 5 + slot 6

    uint128 plpLiquidity;                   // 16B
    uint160 expectedAfterSwapSqrtPriceX96;  // 20B
    int24 expectedAfterSwapTick;            // 3B
    bool zeroForOne;                        // 1B
    // total: 40B → spans slot 6 + slot 7
}


struct SwapCallbackData {
    address sender;
    PoolKey key;
    SwapParams params;
    bytes hookData;
}

struct ModifyLiquidityCallBackData{
    address sender;
    PoolKey key;
    ModifyLiquidityParams params;
    bytes hookData;
}

/// @custom:transient-storage-location erc7201:openzeppelin.transient-storage.JIT_TRANSIENT
struct JIT_Transient_Metrics{
    //slot 1 
    uint256 addedLiquidity;
    //slot 2
    bytes32 positionKey;
    // slot 3 
    bytes32 jitPositionInfo;
    // slot 4 
    uint256 jitProfit;
    // slot 5 
    int256 withheldFees;
}

/// @custom:storage-location erc7201:openzeppelin.storage.JIT_Aggregate_Metrics
struct JIT_Aggregate_Metrics{
    uint256 cummAddedLiquidity;
    uint256 cummProfit;
}




