// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/hooks/LiquidityOperator.sol";

contract InvalidOperator is LiquidityOperator {
    constructor(
        IPoolManager _poolManager,
        ITradingFeeRevenueDB _tradingFeeRevenueDB,
        ITaxController _taxController
    ) LiquidityOperator(_poolManager, _tradingFeeRevenueDB, _taxController) {}

    function getHookPermissions()
        public
        pure
        virtual
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: true, // NOTE: This is
                // what makes it invalid
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeInitialize(
        address,
        PoolKey calldata,
        uint160
    ) internal pure override returns (bytes4) {
        return IHooks.beforeInitialize.selector;
    }
}
