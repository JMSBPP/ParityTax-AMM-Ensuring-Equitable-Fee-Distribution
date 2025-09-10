// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {FeeRevenueInfo} from "../types/FeeRevenueInfo.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolId.sol";
// TODO: This needs to inherit IERC4626

interface ITaxController {


    function getTaxRate() external returns(uint24);


    function getJitTaxLiability(BalanceDelta jitFeeRevenueDelta) external returns (BalanceDelta);
    function getPlpTaxCredit(uint256 plpPositionTokenId) external returns(BalanceDelta);
    
    function filTaxReport(PoolKey memory,FeeRevenueInfo) external;    
}
