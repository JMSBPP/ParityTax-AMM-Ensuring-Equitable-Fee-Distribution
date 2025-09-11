// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  "../../src/base/TaxControllerBase.sol";
import {BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {MockERC4626} from "@solmate/test/utils/mocks/MockERC4626.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";
// TODO: This is meant to be initializable proxy

import {FeeRevenueInfo} from "../../src/types/FeeRevenueInfo.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolId.sol";

contract LumpSumTaxController is TaxControllerBase{
    using BalanceDeltaLibrary for BalanceDelta;

    constructor(
        ILPOracle __lpOracle,
        IParityTaxRouter __router
    ) TaxControllerBase(__lpOracle, __router){}


    function _filTaxReport(PoolKey memory poolKey, FeeRevenueInfo) internal override{
    }


    // TODO: This is a placeHolder
    function getJitTaxLiability(BalanceDelta jitFeeRevenueDelta) external returns (BalanceDelta){
        return BalanceDeltaLibrary.ZERO_DELTA;
    }

    // TODO: This is a placeHolder
    function getPlpTaxCredit(uint256 plpPositionTokenId) external returns(BalanceDelta){
        return BalanceDeltaLibrary.ZERO_DELTA;
    }
    
    function getTaxRate() external returns(uint24){

    }




}

