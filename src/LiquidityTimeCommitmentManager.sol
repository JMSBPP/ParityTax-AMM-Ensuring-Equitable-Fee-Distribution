// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/base/SafeCallback.sol";
import "./interfaces/ILiquidityManager.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/Currency.sol";
import "v4-periphery/src/base/ImmutableState.sol";

contract LiquidityTimeCommitmentManager is ImmutableState, ILiquidityManager {
    using CurrencyLibrary for Currency;
    constructor(IPoolManager _poolManager) ImmutableState(_poolManager) {}

    function getClaimableLiquidityOnCurrencies(
        PoolKey memory poolKey
    )
        public
        view
        virtual
        returns (
            uint256 claimableLiquidityOnCurrency0,
            uint256 claimableLiquidityOnCurrency1
        )
    {
        (claimableLiquidityOnCurrency0, claimableLiquidityOnCurrency1) = (
            poolManager.balanceOf(address(this), poolKey.currency0.toId()),
            poolManager.balanceOf(address(this), poolKey.currency1.toId())
        );
    }
}
