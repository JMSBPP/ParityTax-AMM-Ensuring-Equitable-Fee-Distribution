// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPLPHook} from "../interfaces/IPLPHook.sol";
import "v4-periphery/src/utils/BaseHook.sol";

abstract contract PLPHookBase is BaseHook, IPLPHook {
    constructor(IPoolManager _manager) BaseHook(_manager) {}
    // TODO: This function can not be further overwritten, or if it can be overwriteen
    // is to ADD persmissions and NOT remove them such that it does not change the
    // JIT funcitonality and most importantly the ability to tax the JIT.
    function getHookPermissions()
        public
        pure
        virtual
        override(BaseHook)
        returns (Hooks.Permissions memory permissions)
    {
        permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: true, //NOTE: This enables me the ability to transfer
            // JIT tax fee revenue to PLP's
            afterRemoveLiquidityReturnDelta: false
        });
    }
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    )
        external
        virtual
        override(BaseHook, IPLPHook)
        onlyPoolManager
        returns (bytes4, BalanceDelta)
    {
        return
            _afterAddLiquidity(
                sender,
                key,
                params,
                delta,
                feesAccrued,
                hookData
            );
    }
}
