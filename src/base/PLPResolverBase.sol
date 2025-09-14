// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";

import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";



import "../types/Shared.sol";
import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import "./ResolverBase.sol";

abstract contract PLPResolverBase is IPLPResolver,ResolverBase{
    
    struct YieldGenerator{
        IERC4626 yieldOnCurrency0;
        IERC4626 yieldOnCurrency1;
    }
    
    mapping(PoolId => YieldGenerator) pairYieldGenerator;


    
    
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook
    ) ResolverBase(_poolManager, _lpm,_parityTaxHook){
    }

    function commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        address committer,
        uint48 blockNumber
    ) external onlyWithHookInitialized() onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256){
        //NOTE Associates the committer with the owner of the position
        uint256 tokenId = lpm.nextTokenId();

        PositionConfig memory plpPosition = PositionConfig({
            poolKey: poolKey,
            tickLower: liquidityParams.tickLower,
            tickUpper: liquidityParams.tickUpper
        });

        _mintUnlocked(
            plpPosition,
            uint256(liquidityParams.liquidityDelta),
            committer,
            Constants.ZERO_BYTES
        );
        _commitLiquidity(poolKey, liquidityParams, committer, blockNumber);
        return tokenId;
    }


    function removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) external onlyWithHookInitialized() onlyRole(DEFAULT_ADMIN_ROLE){}
    

    function _commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        address committer,
        uint48 blockNumber
    ) internal virtual returns(uint256){}

    function _removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) internal virtual{}

    

    

}


