// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITaxController} from "../../src/interfaces/ITaxController.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {MockPLPOperator} from "./MockPLPOperator.sol";
import {MockJITOperator} from "./MockJITOperator.sol";
import {MockERC4626} from "@solmate/test/utils/mocks/MockERC4626.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";
// TODO: This is meant to be initializable proxy



contract LumpSumTaxController is ITaxController{
    using BalanceDeltaLibrary for BalanceDelta;


    MockPLPOperator plpOperator;
    MockJITOperator jitOperator;

    constructor(
        // MockERC20 _revenueToken,
        // string memory name,
        // string memory symbol,
        MockPLPOperator _plpOperator,
        MockJITOperator _jitOperator
    ){
        plpOperator = _plpOperator;
        jitOperator = _jitOperator;
    }

    
    function taxJITFeeRevenue(
        BalanceDelta totalFees
    ) external returns(BalanceDelta){
        //TODO: This is a placeHolder
        return BalanceDeltaLibrary.ZERO_DELTA;    
    }


}

