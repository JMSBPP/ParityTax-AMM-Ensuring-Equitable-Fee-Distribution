// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";

import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";



import "../types/Shared.sol";
import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./ResolverBase.sol";

abstract contract PLPResolverBase is IPLPResolver,ResolverBase, AccessControl{
    
    struct YieldGenerator{
        IERC4626 yieldOnCurrency0;
        IERC4626 yieldOnCurrency1;
    }
    //keccak256("EXCECUTOR_ROLE")
    bytes32 constant EXCECUTOR_ROLE = 0x0338ac0c1e3cf2299a976fd2902e19234ca77788bc707be23f61be34208d979d;

    mapping(PoolId => YieldGenerator) pairYieldGenerator;


    IParityTaxHook parityTaxHook;
    IParityTaxRouter parityTaxRouter;

    error HookHasNotBeenSet();
    error HookHasAlreadyBeenSet();
    
    constructor(
        IPoolManager _poolManager,
        IParityTaxRouter _parityTaxRouter,
        IPositionManager _lpm
    ) ResolverBase(_poolManager, _lpm){
        parityTaxRouter = _parityTaxRouter;
    }

    modifier onlyWithHookInitialized(){
        if (address(parityTaxHook) == address(0x00)) revert HookHasNotBeenSet();
        _;
    }


    //TODO: This function is to be called only once
    // and only by the protocol deployer
    function setParityTaxHook(
        IParityTaxHook _parityTaxHook
    ) external {
        if (address(parityTaxHook) != address(0x00)) revert HookHasAlreadyBeenSet();
        parityTaxHook = _parityTaxHook;
        _grantRole(DEFAULT_ADMIN_ROLE, address(parityTaxHook));
        
    }


    

    

}


