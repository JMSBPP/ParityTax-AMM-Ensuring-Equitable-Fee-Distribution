// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title UniformFiscalPolicy
 * @author ParityTax Team
 * @notice Mock implementation of fiscal policy for lump sum tax testing
 * @dev This contract provides a test implementation of the fiscal policy functionality,
 * implementing a uniform tax calculation strategy for testing lump sum taxation in the
 * ParityTax system. It calculates tax rates based on pool liquidity provider fees
 * with a fixed offset, providing a simple and predictable tax model for testing.
 * @dev Inherits from FiscalPolicyBase and implements the virtual tax calculation functions
 * for testing the equitable fee distribution system's taxation mechanisms.
 * @dev TODO: This is meant to be initializable proxy
 */

import  "../../src/base/FiscalPolicyBase.sol";
import {BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {MockERC4626} from "@solmate/test/utils/mocks/MockERC4626.sol";
import {MockERC20} from "@solmate/test/utils/mocks/MockERC20.sol";

import {FeeRevenueInfo} from "../../src/types/FeeRevenueInfo.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolId.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";

/**
 * @notice Mock implementation of fiscal policy for lump sum tax testing
 * @dev Provides uniform tax calculation for testing purposes
 */
contract UniformFiscalPolicy is FiscalPolicyBase{
    using BalanceDeltaLibrary for BalanceDelta;
    using StateLibrary for IPoolManager;

    // ================================ CONSTANTS ================================
    
    /// @notice Fixed offset for tax rate calculation in testing
    /// @dev Used to calculate uniform tax rate by subtracting from pool LP fee
    uint24 constant internal TEST_TAX_RATE_OFFSET = 400;

    // ================================ CONSTRUCTOR ================================
    
    /**
     * @notice Initializes the UniformFiscalPolicy with reactive network dependencies
     * @dev Sets up the mock fiscal policy for testing lump sum taxation mechanisms
     * @param _callbackSender The address authorized to send reactive network callbacks
     * @param __lpOracle The liquidity provider oracle for price and liquidity data
     * @param __lpm The Uniswap V4 position manager contract
     * @param _parityTaxHook The ParityTax hook contract for event data integration
     */
    constructor(
        address _callbackSender,
        ILPOracle __lpOracle,
        IPositionManager __lpm,
        IParityTaxHook _parityTaxHook
    ) FiscalPolicyBase(_callbackSender,__lpOracle, __lpm, _parityTaxHook){}

    // ================================ INTERNAL FUNCTIONS ================================

    /**
     * @notice Mock implementation of optimal tax calculation for lump sum taxation
     * @dev Calculates a uniform tax rate by subtracting a fixed offset from the pool's
     * liquidity provider fee. This provides a simple and predictable tax model for
     * testing lump sum taxation mechanisms in the ParityTax system.
     * @return uint24 The calculated uniform tax rate in pips (1/10000)
     */
    function _calculateOptimalTax(PoolId poolId ,bytes memory) internal virtual override returns(uint24){
        (,,, uint24 lpFee) = lpm.poolManager().getSlot0(poolId);
        return lpFee - TEST_TAX_RATE_OFFSET;
    }


}

