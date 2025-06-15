// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/utils/BaseHook.sol";
import {IJITHook} from "../interfaces/IJITHook.sol";

// TODO: The after swap is an afterSwapReturnDelta because this way we cna charge taxes on
// the output token then, rather than enforrcing JITHooks to comply with an interface we need
// JITHooks to be compliant to be compliant with an anstract contract, then ...

abstract contract JITHookBase is BaseHook, IJITHook {
    constructor(IPoolManager _manager) BaseHook(_manager) {}

    // TODO: This function can not be further overwritten, or if it can be overwriteen
    // is to ADD persmissions and NOT remove them such that it does not change the
    // JIT funcitonality and most importantly the ability to tax the JIT.
    function getHookPermissions()
        public
        pure
        override(BaseHook)
        returns (Hooks.Permissions memory permissions)
    {
        permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true, // NOTE: JIT deteermines to fullfill the swap and
            // what amounts, and deposits liquidity
            afterSwap: true, //NOTE: JIT withdraws the liquidity used to fullfill the swap
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false, //NOTE: For example, this can be ENABLED in case the
            // underlying pool where JIT liquidity is being provided implements customCurve logic
            // but this is a feature rather than a requirement ...
            afterSwapReturnDelta: true, //NOTE: Taxation system charges tax on feeRevenue
            // after withdrawing liquidity
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    )
        external
        override(BaseHook, IJITHook)
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        return _beforeSwap(sender, key, params, hookData);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override(BaseHook, IJITHook) returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }
}
