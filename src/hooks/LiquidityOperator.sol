// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITradingFeeRevenueDB} from "../interfaces/ITradingFeeRevenueDB.sol";
import "v4-periphery/src/utils/BaseHook.sol";

import "./interfaces/ILiquidityOperator.sol";
import "../interfaces/ITaxController.sol";

import "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

abstract contract LiquidityOperator is BaseHook, ERC165, ILiquidityOperator {
    ITradingFeeRevenueDB private tradingFeeRevenueDB;

    // NOTE: In pracice there will be polymorphism
    // when the operator is JIT, the tax
    // controller is a tax gathered and when it is a plp
    // it will be a income distributor
    ITaxController private taxController;
    constructor(
        IPoolManager _poolManager,
        ITradingFeeRevenueDB _tradingFeeRevenueDB,
        ITaxController _taxController
    ) BaseHook(_poolManager) {}
}
