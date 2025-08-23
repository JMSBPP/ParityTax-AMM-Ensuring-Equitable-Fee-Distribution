// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";
import {IJITOperator} from "../../src/interfaces/IJITOperator.sol";
import {
    PositionInfo,
    PositionInfoLibrary
} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";



contract MockJITOperator is LiquidityOperations, IJITOperator{
    using PositionInfoLibrary for PositionInfo;


    using Planner for Plan;
    
    constructor(
        address _positionManager
    ){
        lpm = IPositionManager(_positionManager);
    }

    function addJITLiquidity(
        PoolKey calldata poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint128 addLiquidityDelta,
        address recipient,
        bytes calldata hookData
        
    ) external {
        mint(
            PositionConfig({
                poolKey: poolKey,
                tickLower: tickLower,
                tickUpper: tickUpper
            }),
            uint256(addLiquidityDelta),
            recipient,
            hookData
        );
    }


   function removeJITLiquidity(
        bytes32 jitPositionKey,
        bytes calldata hookData
    ) external{
        uint256 jitTokenId = uint256(jitPositionKey);
        (PoolKey memory poolKey ,PositionInfo jitPositionInfo) = lpm.getPoolAndPositionInfo(jitTokenId);
        burn(
            jitTokenId,
            PositionConfig({
                poolKey: poolKey,
                tickLower: jitPositionInfo.tickLower(),
                tickUpper: jitPositionInfo.tickUpper()
            }),
            hookData
        );       
    }



}




