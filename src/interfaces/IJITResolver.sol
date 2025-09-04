//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IExttload} from "@uniswap/v4-core/src/interfaces/IExttload.sol";

interface IJITResolver, IExttload{

    function jitLiquidityLocation() external returns(bytes32);
    fucntion jitPositionKeyLocation() external returns(bytes32);
    function addLiquidity(JITData memory jitData) external returns(uint256);

    function removeLiquidity(uint256 tokenId) external;


}