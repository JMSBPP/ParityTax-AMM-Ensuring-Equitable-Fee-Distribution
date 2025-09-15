// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import  "../../src/base/FiscalPolicyBase.sol";
import {BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {MockERC4626} from "@solmate/test/utils/mocks/MockERC4626.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";
// TODO: This is meant to be initializable proxy

import {FeeRevenueInfo} from "../../src/types/FeeRevenueInfo.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolId.sol";


import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

contract UniformFiscalPolicy is FiscalPolicyBase{
    using BalanceDeltaLibrary for BalanceDelta;
    using StateLibrary for IPoolManager;

 
    uint24 constant internal TEST_TAX_RATE_OFFSET = 400;
    constructor(
        address _callbackSender,
        ILPOracle __lpOracle,
        IPositionManager __lpm,
        IParityTaxHook _parityTaxHook
    ) FiscalPolicyBase(_callbackSender,__lpOracle, __lpm, _parityTaxHook){}



    function _calculateOptimalTax(PoolId poolId ,bytes memory) internal virtual override returns(uint24){
        (,,, uint24 lpFee) = lpm.poolManager().getSlot0(poolId);
        return lpFee - TEST_TAX_RATE_OFFSET;
    }


}

