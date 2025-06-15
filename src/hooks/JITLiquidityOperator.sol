// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./LiquidityOperator.sol";
import {IJITHook} from "./interfaces/IJITHook.sol";
import "./mining/JITHookMiner.sol";
import "./base/JITHookBase.sol";
contract JITLiquidityOperator is LiquidityOperator, JITHookBase {
    using CurrencyLibrary for Currency;
    // TODO: The liquidity Operator receives tww ERC6909 tokens
    // wnen liquidity is added and directed here through the
    // liquidityTimeCommitmentManager

    constructor(IPoolManager _manager) JITHookBase(_manager) {}
    function getClaimableLiquidityOnCurrency(
        Currency currency
    ) external view returns (uint256 claimableLiquidityBalance) {
        claimableLiquidityBalance = poolManager.balanceOf(
            address(this),
            currency.toId()
        );
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        return _beforeSwap(sender, key, params, hookData);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external override returns (bytes4, int128) {
        return _afterSwap(sender, key, params, delta, hookData);
    }
}
