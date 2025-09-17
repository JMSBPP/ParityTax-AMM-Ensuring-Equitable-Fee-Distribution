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
    uint24 constant internal HIGH_TAX_RATE = 400;
    uint24 constant internal LOW_TAX_RATE = 200;

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
        PriceImpactCallback memory priceImpactCallback = _tload_priceImpactCallback();
        LiquidityOnSwapCallback memory liquidityOnSwapCallback = _tload_liquidityOnSwapCallback();
        // int256 orderFlowElasticity = _calculateOrderFlowElasticity(liquidityOnSwapCallback, priceImpactCallback);
        uint256 concentration = (liquidityOnSwapCallback.jitLiquidity * 10000) / (liquidityOnSwapCallback.jitLiquidity + liquidityOnSwapCallback.plpLiquidity);


        if (concentration > 5000) {
            return uint24(HIGH_TAX_RATE);  
        } else{
            return uint24(LOW_TAX_RATE);
        }
    }

    function _accrueCredit(PoolId,bytes memory) internal virtual override returns(uint256,uint256){
        // TODO: Here is where developers implement custom logic for rewarding distribution
        // This function is called on afterDonate to map the plp's commitment to the credit accrual
        // based on the multipliers for both currencies by this function
    } 

    function _onLiquidityOnSwap(PoolId /*poolId*/, LiquidityOnSwapCallback memory liquidityOnSwapCallback) internal virtual override returns(bytes memory){
        uint48 blockNumber = liquidityOnSwapCallback.blockNumber;
        uint128 totalLiquidity = liquidityOnSwapCallback.totalLiquidity;
        uint128 jitLiquidity = liquidityOnSwapCallback.jitLiquidity;
        uint128 plpLiquidity = liquidityOnSwapCallback.plpLiquidity;

        assembly("memory-safe") {
            tstore(LIQUIDITY_ON_SWAP_LOCATION, blockNumber)
            tstore(add(LIQUIDITY_ON_SWAP_LOCATION, 0x01), totalLiquidity)
            tstore(add(LIQUIDITY_ON_SWAP_LOCATION, 0x02), jitLiquidity)
            tstore(add(LIQUIDITY_ON_SWAP_LOCATION, 0x03), plpLiquidity)
        }

        return bytes("");
    }

    function _onPriceImpact(PoolId /*poolId*/, PriceImpactCallback memory priceImpactCallback) internal virtual override returns(bytes memory){
        // NOTE: Stores the PriceImpactCallback in transient storage
        uint160 beforeSwapSqrtPriceX96 = priceImpactCallback.beforeSwapSqrtPriceX96;
        uint160 beforeSwapExternalSqrtPriceX96 = priceImpactCallback.beforeSwapExternalSqrtPriceX96;
        uint160 afterSwapSqrtPriceX96 = priceImpactCallback.afterSwapSqrtPriceX96;
        uint160 afterSwapExternalSqrtPriceX96 = priceImpactCallback.afterSwapExternalSqrtPriceX96;
        uint48 blockNumber = priceImpactCallback.blockNumber;
        SwapIntent swapIntent = priceImpactCallback.swapIntent;
        BalanceDelta swapDelta = priceImpactCallback.swapDelta;

        assembly("memory-safe") {
            tstore(PRICE_IMPACT_LOCATION, beforeSwapSqrtPriceX96)
            tstore(add(PRICE_IMPACT_LOCATION, 0x01), beforeSwapExternalSqrtPriceX96)
            tstore(add(PRICE_IMPACT_LOCATION, 0x02), afterSwapSqrtPriceX96)
            tstore(add(PRICE_IMPACT_LOCATION, 0x03), afterSwapExternalSqrtPriceX96)
            tstore(add(PRICE_IMPACT_LOCATION, 0x04), blockNumber)
            tstore(add(PRICE_IMPACT_LOCATION, 0x05), swapIntent)
            tstore(add(PRICE_IMPACT_LOCATION, 0x06), swapDelta)
        }

        return bytes("");
    }

    function _tload_priceImpactCallback() internal view returns(PriceImpactCallback memory priceImpactCallback){
        uint160 beforeSwapSqrtPriceX96;
        uint160 beforeSwapExternalSqrtPriceX96;
        uint160 afterSwapSqrtPriceX96;
        uint160 afterSwapExternalSqrtPriceX96;
        uint48 blockNumber;
        SwapIntent swapIntent;
        BalanceDelta swapDelta;

        assembly("memory-safe") {
            beforeSwapSqrtPriceX96 := tload(PRICE_IMPACT_LOCATION)
            beforeSwapExternalSqrtPriceX96 := tload(add(PRICE_IMPACT_LOCATION, 0x01))
            afterSwapSqrtPriceX96 := tload(add(PRICE_IMPACT_LOCATION, 0x02))
            afterSwapExternalSqrtPriceX96 := tload(add(PRICE_IMPACT_LOCATION, 0x03))
            blockNumber := tload(add(PRICE_IMPACT_LOCATION, 0x04))
            swapIntent := tload(add(PRICE_IMPACT_LOCATION, 0x05))
            swapDelta := tload(add(PRICE_IMPACT_LOCATION, 0x06))
        }

        priceImpactCallback = PriceImpactCallback({
            blockNumber: blockNumber,
            swapIntent: swapIntent,
            swapDelta: swapDelta,
            beforeSwapSqrtPriceX96: beforeSwapSqrtPriceX96,
            beforeSwapExternalSqrtPriceX96: beforeSwapExternalSqrtPriceX96,
            afterSwapSqrtPriceX96: afterSwapSqrtPriceX96,
            afterSwapExternalSqrtPriceX96: afterSwapExternalSqrtPriceX96
        });

        return priceImpactCallback;
    }

    function _tload_liquidityOnSwapCallback() internal view returns(LiquidityOnSwapCallback memory liquidityOnSwapCallback){
        uint48 blockNumber;
        uint128 totalLiquidity;
        uint128 jitLiquidity;
        uint128 plpLiquidity;

        assembly("memory-safe") {
            blockNumber := tload(LIQUIDITY_ON_SWAP_LOCATION)
            totalLiquidity := tload(add(LIQUIDITY_ON_SWAP_LOCATION, 0x01))
            jitLiquidity := tload(add(LIQUIDITY_ON_SWAP_LOCATION, 0x02))
            plpLiquidity := tload(add(LIQUIDITY_ON_SWAP_LOCATION, 0x03))
        }

        liquidityOnSwapCallback = LiquidityOnSwapCallback({
            blockNumber: blockNumber,
            totalLiquidity: totalLiquidity,
            jitLiquidity: jitLiquidity,
            plpLiquidity: plpLiquidity
        });

        return liquidityOnSwapCallback;
    }

    function _calculateOrderFlowElasticity(
        LiquidityOnSwapCallback memory liquidityOnSwapCallback,
        PriceImpactCallback memory priceImpactCallback
    ) private pure returns(int256){
    }


}

