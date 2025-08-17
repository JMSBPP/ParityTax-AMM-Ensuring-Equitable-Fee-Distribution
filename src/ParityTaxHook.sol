// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import {BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

//NOTE: This Hook aims to povide JITHook on beforeSWap and
// aftyeerSwap and apply  time commitmeent liquidity tracking
// and control on afterAddLiqudity for identifying if the
// LP is PLP or JIT and beforeDonate    

abstract contract PairtyTaxHook is BaseHook{
    function getHookPermissions() public pure override virtual returns (Hooks.Permissions memory){
        return Hooks.Permissions({
            beforeInitialize: true, // Uses price oracle to 
            afterInitialize: false,
            beforeAddLiquidity: false,  
            afterAddLiquidity: true, //
            beforeRemoveLiquidity:true,
            afterRemoveLiquidity:true,
            beforeSwap:true,
            afterSwap:true,
            beforeDonate:false,
            afterDonate:false,
            beforeSwapReturnDelta:false,
            afterSwapReturnDelta:false,
            afterAddLiquidityReturnDelta:false,
            afterRemoveLiquidityReturnDelta:false
        });
    }

    constructor(IPoolManager _manager) BaseHook(_manager){}

    function _beforeSwap(
        address, 
        PoolKey calldata, 
        SwapParams calldata,
        bytes calldata
        ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24)
    {        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);

    }




    function _afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        virtual
        override
        returns (bytes4, int128)
        {

        }

}
