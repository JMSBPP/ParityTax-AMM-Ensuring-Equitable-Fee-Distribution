// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";
import "../../src/base/PLPResolverBase.sol";
import {PositionConfig} from "@uniswap/v4-periphery/test/shared/PositionConfig.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";


contract MockPLPResolver is IPLPResolver, PLPResolverBase{
    using SafeCast for *;
    using Address for address;
    using PositionInfoLibrary for PositionInfo;
    
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook 
    ) PLPResolverBase(_poolManager, _lpm, _parityTaxHook){}

    // function _commitLiquidity(
    //     PoolKey memory poolKey,
    //     ModifyLiquidityParams memory liquidityParams,
    //     uint48 blockNumber
    // ) internal override {
    // }
    
    //TODO: PLP's do not necesarilly have to burn their position but they can 
    // Do liquidity DECREASE operations that do not empty their positions as long as
    // their position block commitment has already expired
    function _removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) internal override {
        
        PositionInfo plpPositionInfo = lpm.positionInfo(tokenId);
        
        uint256 plpPositionLiquidity = lpm.getPositionLiquidity(tokenId);
        
        PoolKey memory poolKey = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "poolKeys(bytes25)", 
                    (plpPositionInfo.poolId()))
            ),
            (PoolKey)
        );

        PositionConfig memory plpPositionConfig = PositionConfig({
            poolKey: poolKey,
            tickLower: plpPositionInfo.tickLower(),
            tickUpper: plpPositionInfo.tickUpper()
        });


        if (uint256(liquidityDelta) == plpPositionLiquidity){
            _burnUnlocked(
                tokenId,
                plpPositionConfig
            );
        } else if (uint256(liquidityDelta) < plpPositionLiquidity){
            _decreaseUnlocked(
                tokenId,
                plpPositionConfig,
                uint256(liquidityDelta)
            );
        }
        
    }



}