// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityOperator.sol";
import "v4-core/types/BeforeSwapDelta.sol";
import "v4-core/types/BalanceDelta.sol";
// import {IEthereumVaultConnector} from "ethereum-vault-connector/src/interfaces/IEthereumVaultConnector.sol";

contract PLPLiquidityOperator is
    LiquidityOperator // IEthereumVaultConnector private yieldFarmer;
{
    constructor(
        IPoolManager _poolManager,
        ITradingFeeRevenueDB _tradingFeeRevenueDB,
        ITaxController _taxController
    )
        // IEthereumVaultConnector _yieldFarmer
        LiquidityOperator(_poolManager, _tradingFeeRevenueDB, _taxController)
    {}

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
                beforeAddLiquidity: true,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: true, // NOTE: This will be implemented
                // to distrinute fee income using USDC streams
                // plugin with circle throug the taxController
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: true,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }
    function _beforeAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        bytes calldata
    ) internal virtual override returns (bytes4) {
        return (IHooks.beforeAddLiquidity.selector);
    }

    function _beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        bytes calldata
    ) internal virtual override returns (bytes4) {
        return (IHooks.beforeRemoveLiquidity.selector);
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, BalanceDelta) {
        BalanceDelta plpOperatorDelta = delta;
        //NOTE:The manager is the caller (a.k.a msg.sender = poolManager)
        return (IHooks.beforeAddLiquidity.selector, plpOperatorDelta);
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) internal virtual override returns (bytes4, BalanceDelta) {
        return (
            IHooks.afterRemoveLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
        );
    }
}
