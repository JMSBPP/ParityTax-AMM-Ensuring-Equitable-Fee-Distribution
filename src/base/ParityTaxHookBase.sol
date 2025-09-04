//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PositionInfoLibrary, PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";

//==================================================================
import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/librariees/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
//====================================================================

//==============================================================
import {IPLPResolver} from "./interfaces/IPLPResolver.sol";
import {IJITResolver} from "./interfaces/IJITResolver.sol";
import {IParityTaxRouter} from "./interfaces/IParityTaxRouter.sol";
import {ITaxController} from "./interfaces/IParityTaxRouter.sol";
import {ILPOracle} from "./interfaces/ILPOracle.sol";
//==============================================================

abstract contract ParityTaxHookBase is BaseHook{
    using SafeCast for *;
    using Position for address;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;

    IPLPResolver plpResolver;
    IJITResolver jitResolver;
    IParityTaxRouter parityTaxRouter;
    ITaxController taxController;
    ILPOracle lpOracle;


    constructor(
        IPoolManager _poolManager,
        IJITResolver _jitResolver,
        IPLPResolver _plpResolver,
        IParityTaxRouter _parityTaxRouter,
        ITaxController _taxController,
        ILPOracle _lpOracle
    ) BaseHook(_poolManager){
        jitResolver  = _jitResolver;
        plpResolver = _plpResolver;
        parityTaxRouter = _parityTaxRouter;
        taxController = _taxController;
        lpOracle = _lpOracle;
    }

    function getHookPermissions() public pure virtual override returns (Hooks.Permissions memory){
        return Hooks.Permissions({
            beforeInitialize: true,      // NOTE: ILPOracle -> sync the internal price with the external one
            afterInitialize: false,  
            beforeAddLiquidity: true,    //NOTE: Handles the commitment of PLP's and JIT's 
            afterAddLiquidity: true,     //NOTE:
            beforeRemoveLiquidity: true, //NOTE:
            afterRemoveLiquidity: true,  //NOTE:
            beforeSwap: true,            //NOTE:
            afterSwap: true,             //NOTE:
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta:false,  
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: true, //NOTE:
            afterRemoveLiquidityReturnDelta: true //NOTE:
        });
    }



    function tload_JIT_addedLiquidity() internal view returns(uint256){
        bytes32 jitLiquidityLocation = jitResolver.jitLiquidityLocation();
        return uint256(jitResolver.exttload(jitLiquidityLocation));
    }

    function tload_JIT_positionKey() internal view returns(bytes32){
        bytes32 jitPositionKeyLocation = jitResolver.jitPositionKeyLocation();
        return jitResolver.exttload(jitPositionKeyLocation);
    }
}