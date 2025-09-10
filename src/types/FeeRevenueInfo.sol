//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";


// uint48 startBlock, uint48 commitment, uint80 feeRevenue0, uint80 feeRevenue1
type FeeRevenueInfo is uint256;

using FeeRevenueInfoLibrary for FeeRevenueInfo global;

library FeeRevenueInfoLibrary{
    function init(
        uint48 startBlock,
        uint48 commitment,
        uint256 feeRevenueOn0,
        uint256 feeRevenueOn1
    ) internal view returns(FeeRevenueInfo){

    }

    function toBalanceDelta(
        FeeRevenueInfo feeRevenueInfo
    ) internal view returns(BalanceDelta){}

    function toFeeRevenueInfo(
        BalanceDelta feeDelta,
        uint48 startBlock,
        uint48 commitment
    ) internal view returns(FeeRevenueInfo){}
}