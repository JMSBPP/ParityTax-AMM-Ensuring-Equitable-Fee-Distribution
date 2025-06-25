// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./base/HookCallableBaseHook.sol";

import "./interfaces/ILiquidityOperator.sol";

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import "@uniswap/v4-core/test/utils/CurrencySettler.sol";

abstract contract LiquidityOperator is
    HookCallableBaseHook,
    ERC165,
    ILiquidityOperator
{
    using CurrencySettler for Currency;

    ITradingFeeRevenueDB private tradingFeeRevenueDB;

    // NOTE: In pracice there will be polymorphism
    // when the operator is JIT, the tax
    // controller is a tax gathered and when it is a plp
    // it will be a income distributor
    ITaxController private taxController;

    //NOTE: The position manager allows us to
    // keep track of the positions data handled by the operator
    // modify liquiidty positions without unlock when the pool manager is called
    // from the liquidityTimeCommitmentHook, this is because the LiquidityTimeCommitmentRouter
    // is the unlocked contract, not the liquidityTimeCommitmentHook
    IPositionManager private postionManager;
    constructor(
        IPoolManager _poolManager,
        ITradingFeeRevenueDB _tradingFeeRevenueDB,
        ITaxController _taxController
    ) HookCallableBaseHook(_poolManager) {}

    function setPositionManager(IPositionManager _positionManager) internal {
        postionManager = _positionManager;
    }

    function getPositionManager() external view returns (IPositionManager) {
        return postionManager;
    }
}
