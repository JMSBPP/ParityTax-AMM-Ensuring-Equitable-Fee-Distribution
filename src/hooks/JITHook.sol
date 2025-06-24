// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityOperator.sol";
import "./libs/NonInformedOrdersFilter.sol";

import "v4-core/types/BeforeSwapDelta.sol";

contract JITHook is LiquidityOperator {
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
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true, //NOTE: This needs to be enabled to
                // be delegate callabale by the LiquidityTimeCommitment hook
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false, //TODO: This
                // can be updated to true if the pool has
                // custom curve
                afterSwapReturnDelta: true, // TODO:
                // this is applied by the tax controller
                // to charge the tax over the trading fees
                //
                afterAddLiquidityReturnDelta: true, //NOTE: This needs to be enabled to
                // be conssitent with the LiquidityTimeCommitment hook
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function _beforeSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        bytes calldata
    ) internal virtual override returns (bytes4, BeforeSwapDelta, uint24) {
        return (
            IHooks.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            0
        );
    }

    function _afterSwap(
        address,
        PoolKey calldata,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, int128) {
        return (IHooks.afterSwap.selector, 0);
    }
}
