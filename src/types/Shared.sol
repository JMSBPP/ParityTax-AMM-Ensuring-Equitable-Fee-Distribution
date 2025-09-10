//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";




uint48 constant JIT_COMMITMENT = uint48(0x01);
uint48 constant  MIN_PLP_BLOCK_NUMBER_COMMITMENT = uint48(0x02);
uint256 constant SWAP_CALLBACK_DATA_LENGTH = uint256(0x340);


enum LP_TYPE{
    JIT,
    PLP
}

struct SwapOutput{
    uint256 amountIn;
    uint256 amountOut;
}



struct SwapContext {
    PoolKey poolKey;
    SwapParams swapParams;
    uint256 amountIn;
    uint256 amountOut;
    uint160 beforeSwapSqrtPriceX96;
    uint128 plpLiquidity;                   
    uint160 expectedAfterSwapSqrtPriceX96;  
    int24 expectedAfterSwapTick;

}


struct LiquidityPosition{
    LP_TYPE lpType;
    uint256 blockCommitment;
    uint256 tokenId;
    bytes32 positionKey;
    PositionInfo positionInfo;
    uint256 liquidity;
    uint256 feeRevenueOnCurrency0;
    uint256 feeRevenueOnCurrency1;
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





