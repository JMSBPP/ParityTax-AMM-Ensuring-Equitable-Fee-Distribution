// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {FeeRevenueInfo} from "../types/FeeRevenueInfo.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
// TODO: This needs to inherit IERC4626

import {ILPOracle} from "./ILPOracle.sol";

import {IParityTaxRouter} from "./IParityTaxRouter.sol";
import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";

interface IFiscalPolicy is ISubscriber{ 

    

    function remit(PoolId,FeeRevenueInfo) external returns(BalanceDelta);
    
    function calculateOptimalTax(PoolId,bytes memory) external returns(uint24);

    function accrueCredit(PoolId,bytes memory) external returns(uint256,uint256);

    function onLiquidityCommitmment(PoolId,bytes memory) external returns(bytes memory);

    function lpOracle() external returns(ILPOracle);    

}
