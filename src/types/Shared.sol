//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import "./SwapIntent.sol";

// keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant  JIT_LIQUIDITY_POSITION_LOCATION = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;
// keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.PLP_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant  PLP_LIQUIDITY_POSITION_LOCATION = 0x369fcc6be4409721b124e1944af5cd9c5a8ac6c841854a0f264aead4f039bb00;
// keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.PRICE_IMPACT")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant  PRICE_IMPACT_LOCATION = 0x9a6e024ebb4e856a20885b7e11ce369a95696ac0f9ef8bcb2bc66a08583efa00;

// keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.TAX_RATE")) - 1)) & ~bytes32(uint256(0xff))

bytes32 constant TAX_RATE_SLOT = 0x27ab0422f76b78bf083331c8c5fff9ffc12f6849edb4cd1117fbfe5487d3ed00;

uint48 constant JIT_COMMITMENT = uint48(0x01);
uint48 constant NO_COMMITMENT = uint48(0x00);
uint48 constant  MIN_PLP_BLOCK_NUMBER_COMMITMENT = uint48(0x02);
uint256 constant SWAP_CALLBACK_DATA_LENGTH = uint256(0x340);
uint256 constant LIQUIDITY_COMMITMENT_LENGTH = uint256(0x1e0);
uint256 constant COMMITMENT_LENGTH = uint256(0x40);

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

struct SwapPriceImpactInfo{
    BalanceDelta swapDelta;
    uint160 beforeSwapSqrtPriceX96;
    uint160 beforeSwapExternalSqrtPriceX96;
    uint160 afterSwapSqrtPriceX96;
    uint160 afterSwapExternalSqrtPriceX96;
}


struct LiquidityPosition{
    LP_TYPE lpType;
    uint256 blockCommitment;
    address owner;
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

struct Commitment{
    address committer;
    uint48 blockNumberCommitment;
}


struct PriceImpactCallback{
    uint48 blockNumber;
    SwapIntent swapIntent;
    BalanceDelta swapDelta;
    uint160 beforeSwapSqrtPriceX96;
    uint160 beforeSwapExternalSqrtPriceX96;
    uint160 afterSwapSqrtPriceX96;
    uint160 afterSwapExternalSqrtPriceX96;
}


struct LiquidityOnSwapCallback{
    uint48 blockNumber;
    uint128 totalLiquidity;
    uint128 jitLiquidity;
    uint128 plpLiquidity;
}


struct LiquidityCommittedCallback{
    uint48 blockNumber;
    uint48 commitment;
    address owner;
    uint256 tokenId;
    bytes liquidityParams;
}


struct RemittanceCallback {
    uint48 blockNumber;
    uint48 blockCommitment;
    BalanceDelta feeRevenueDelta;
}




