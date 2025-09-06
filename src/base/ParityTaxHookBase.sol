//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PositionInfoLibrary, PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";
import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";
//==================================================================
import {BaseHook} from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
//====================================================================

//==============================================================
import {IPLPResolver} from "../interfaces/IPLPResolver.sol";
import {IJITResolver} from "../interfaces/IJITResolver.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";
import {ITaxController} from "../interfaces/ITaxController.sol";
import {ILPOracle} from "../interfaces/ILPOracle.sol";
//==============================================================

abstract contract ParityTaxHookBase is BaseHook{
    using SafeCast for *;
    using Position for address;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;

    IPLPResolver plpResolver;
    IJITResolver jitResolver;
    IParityTaxRouter parityTaxRouter;
    IPositionManager lpm;
    ITaxController taxController;
    ILPOracle lpOracle;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant internal JIT_LIQUIDITY_LOCATION = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;

    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IJITResolver _jitResolver,
        IPLPResolver _plpResolver,
        IParityTaxRouter _parityTaxRouter,
        ITaxController _taxController,
        ILPOracle _lpOracle
    ) BaseHook(_poolManager){
        lpm = _lpm;
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

    function _getJitPositionTokenIdAndLiquidity() internal returns(uint256,uint256){
        uint256 jitPositionTokenId;
        assembly("memory-safe"){
            jitPositionTokenId := tload(JIT_LIQUIDITY_LOCATION)
        }

        uint256 jitLiquidity = lpm.getPositionLiquidity(jitPositionTokenId);
        return (jitLiquidity,jitPositionTokenId);
    }

    


}