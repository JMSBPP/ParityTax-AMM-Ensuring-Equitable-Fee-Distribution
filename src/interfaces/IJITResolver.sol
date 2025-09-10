//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {PositionConfig} from "@uniswap/v4-periphery/test/shared/PositionConfig.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import "../types/Shared.sol";

interface IJITResolver{

 
    function addLiquidity(SwapContext memory) external returns(uint256);

    function removeLiquidity(LiquidityPosition memory) external;


}