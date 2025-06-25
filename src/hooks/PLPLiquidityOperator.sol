// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityOperator.sol";
import "v4-core/types/BeforeSwapDelta.sol";
import "v4-core/types/BalanceDelta.sol";
contract PLPLiquidityOperator is
    LiquidityOperator // IEthereumVaultConnector private yieldFarmer;
{
    using CurrencySettler for Currency;
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
                afterAddLiquidityReturnDelta: true,
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

    event DebuggingLiquidityOperatorDelta(int128 dx, int128 dy);
    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BalanceDelta) {
        //NOTE: The debit the poolManager has coming from the added liquidity
        // by the liqudity provider is known by the liquidityOperator
        // --> delta = principal + fees

        //NOTE:The manager is the caller (a.k.a msg.sender = poolManager)
        return (
            IHooks.beforeAddLiquidity.selector,
            BalanceDeltaLibrary.ZERO_DELTA
        );
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
