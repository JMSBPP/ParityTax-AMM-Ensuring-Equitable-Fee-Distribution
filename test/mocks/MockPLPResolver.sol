// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";
import "../../src/base/PLPResolverBase.sol";

contract MockPLPResolver is IPLPResolver, PLPResolverBase{
    constructor(
        IParityTaxRouter _parityTaxRouter,
        IPositionManager _lpm
    ) PLPResolverBase( _parityTaxRouter, _lpm){}

    function commitLiquidity(
        PoolId poolId,
        ModifyLiquidityParams memory liquidityParams,
        uint48 blockNumber
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256){
        return 1;
    }
    
    
    function removeLiquidity(
        PoolId poolId,
        bytes32 positionKey,
        int256 liquidityDelta
    ) external override onlyRole(DEFAULT_ADMIN_ROLE){
        
    }

}