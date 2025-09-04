//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
// import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import "../types/Shared.sol";
interface IJITHub{


    function addLiquidity(JITData memory jitData) external returns(uint256,uint256);

    function removeLiquidity(uint256 tokenId) external;


}