// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v4-periphery/src/utils/BaseHook.sol";
import "../types/LPTimeCommitment.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";

contract LiquidityTimeCommitmentHook is BaseHook {
    using Hooks for IHooks;
    using CurrencySettler for Currency;

    constructor(IPoolManager _manager) BaseHook(_manager) {}

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
                afterAddLiquidity: true, //NOTE: This allow us to delegate calll to the
                // correspoding liquidityOperator
                beforeRemoveLiquidity: true,
                afterRemoveLiquidity: true,
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
                afterAddLiquidityReturnDelta: true, //TODO: This needs to be enabled to
                // be conssitent with the LiquidityTimeCommitment hook
                afterRemoveLiquidityReturnDelta: false
            });
    }
    event DebuggingMsgSender(address sender);
    function _afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal virtual override returns (bytes4, BalanceDelta) {
        //1.  Decode the underlying liquidityTimeCommitment from the hookData
        LPTimeCommitment memory enteredLpTimeCommitment = abi.decode(
            hookData,
            (LPTimeCommitment)
        );

        // NOTE: At this point the poolManager has a debit
        // of delta  coming from the liquidityProvider all we need to do now
        // is allow the liquidityOperator to take this liquidity for
        // future use, this is
        {
            poolManager.approve(
                address(enteredLpTimeCommitment.liquidityOperator),
                key.currency0.toId(),
                uint256(int256(-delta.amount0()))
            );
            poolManager.approve(
                address(enteredLpTimeCommitment.liquidityOperator),
                key.currency1.toId(),
                uint256(int256(-delta.amount1()))
            );
        }

        BalanceDelta liquidityTimeCommitmentHookDelta = delta;
        return (
            IHooks.afterAddLiquidity.selector,
            liquidityTimeCommitmentHookDelta
        );
    }
}
