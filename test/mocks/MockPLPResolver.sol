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
        IParityTaxRouter _parityTaxRouter,
        IPositionManager _lpm
    ) PLPResolverBase(_poolManager,_parityTaxRouter, _lpm){}

    function commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        uint48 blockNumber
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256){
        uint256 tokenId = lpm.nextTokenId();

        PositionConfig memory plpPosition = PositionConfig({
            poolKey: poolKey,
            tickLower: liquidityParams.tickLower,
            tickUpper: liquidityParams.tickUpper
        });


        _mintUnlocked(
            plpPosition,
            uint256(liquidityParams.liquidityDelta),
            address(this),
            Constants.ZERO_BYTES
        );
        
        return tokenId;
    }
    
    //TODO: PLP's do not necesarilly have to burn their position but they can 
    // Do liquidity DECREASE operations that do not empty their positions as long as
    // their position block commitment has already expired
    function removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) external override onlyRole(DEFAULT_ADMIN_ROLE){
        
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