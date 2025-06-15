// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./LiquidityOperator.sol";
import {IPLPHook} from "./interfaces/IPLPHook.sol";
import "./base/PLPHookBase.sol";

contract PLPLiquidityOperator is LiquidityOperator, PLPHookBase {
    constructor(IPoolManager _manager) PLPHookBase(_manager) {}
    function getHookPermissions()
        public
        pure
        override
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
    ) external override onlyPoolManager returns (bytes4, BalanceDelta) {
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
    function getClaimableLiquidityOnCurrency(
        Currency currency
    ) external view returns (uint256 claimableLiquidityBalance) {
        claimableLiquidityBalance = poolManager.balanceOf(
            address(this),
            currency.toId()
        );
    }
}
