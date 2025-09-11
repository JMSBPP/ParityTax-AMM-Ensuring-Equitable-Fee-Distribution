// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {FeeRevenueInfo} from "../types/FeeRevenueInfo.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
// TODO: This needs to inherit IERC4626

import {ILPOracle} from "./ILPOracle.sol";

import {IParityTaxRouter} from "./IParityTaxRouter.sol";


interface ITaxController{ 

    event TaxFiling (bytes32 indexed poolId,uint48 indexed currentBlock, uint48 indexed blockCommitment, BalanceDelta feeRevenueDelta);
    
    function getTaxRate() external returns(uint24);


    function getJitTaxLiability(BalanceDelta jitFeeRevenueDelta) external returns (BalanceDelta);
    function getPlpTaxCredit(uint256 plpPositionTokenId) external returns(BalanceDelta);
    
    function filTaxReport(PoolKey memory,FeeRevenueInfo) external;

    function router() external returns(IParityTaxRouter);
    function lpOracle() external returns(ILPOracle);    

}
