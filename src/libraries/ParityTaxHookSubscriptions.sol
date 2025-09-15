// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";

/// @dev Constant used to ignore specific topic filters in reactive network subscriptions
uint256 constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

/// @dev Topic0 for PriceImpact event: PriceImpact(bytes32,uint48,SwapIntent,BalanceDelta,uint160,uint160,uint160,uint160)
uint256 constant PRICE_IMPACT_TOPIC0 = 0x5893daed40175f5b967e0d8330bb4645462baa4dd943a1d477970a09005d0eba;

/// @dev Topic0 for LiquidityOnSwap event: LiquidityOnSwap(bytes32,uint48,uint128,uint128,uint128)
uint256 constant LIQUIDITY_ON_SWAP_TOPIC0 = 0xc8880b3ae9558df3a51b833923827bbd2f9ba44a9e301b9fc30c9ebc9b74f98a;

/// @dev Topic0 for LiquidityCommitted event: LiquidityCommitted(bytes32,uint48,uint48,address,uint256,bytes)
uint256 constant LIQUIDITY_COMMITTED_TOPIC0 = 0xcec8de8a7601b90797cedff00dcb85732045825d1bf02308be5874f59bc616d4;

/// @dev Topic0 for Remittance event: Remittance(bytes32,uint48,uint48,BalanceDelta)
uint256 constant REMITTANCE_TOPIC0 = 0x58dfacde9fc85654a0cc8143d1b2311ae404acab04d626a660c0a45db26c891c;

/// @dev Total number of ParityTax hook events that can be subscribed to
uint256 constant NUMBER_EVENTS = uint256(0x04);


/**
 * @title ParityTaxHookSubscriptions
 * @author ParityTax Team
 * @notice Library for generating reactive network subscription data for ParityTax hook events
 * @dev This library is a critical component of the reactive network architecture, responsible for
 * generating subscription data that enables FiscalListeningPost to listen to specific events from
 * the ParityTax hook system. It defines the event topics and creates encoded subscription calls
 * for the reactive network to process liquidity events, fee collections, and swap activities.
 * @dev Contains all event topic constants and subscription generation logic for optimal tax calculations
 */
library ParityTaxHookSubscriptions{
     
    /**
     * @notice Generates subscription data for all ParityTax hook events
     * @dev This function creates encoded subscription calls for all four ParityTax hook events:
     * PriceImpact, LiquidityOnSwap, LiquidityCommitted, and Remittance. These subscriptions enable
     * the reactive network to forward event data to the fiscal policy for real-time tax calculations.
     * @param _parityTaxHook The ParityTaxHook contract address to subscribe to events from
     * @param _chainId The blockchain chain ID for the reactive network subscriptions
     * @return subscriptions Array of encoded subscription calls for all ParityTax hook events
     * @dev TODO: Topics of all events - consider adding more event types as they are implemented
     */
    function getSubscriptions(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId
    ) internal view returns(bytes[] memory){
        
        // Initialize subscriptions array with the total number of events
        bytes[] memory subscriptions = new bytes[](NUMBER_EVENTS);
        
        // PriceImpact event subscription - tracks price changes during swaps for tax calculation
        subscriptions[0] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            PRICE_IMPACT_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        // LiquidityOnSwap event subscription - tracks liquidity distribution during swaps
        subscriptions[1] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            LIQUIDITY_ON_SWAP_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        // LiquidityCommitted event subscription - tracks liquidity commitments for PLP providers
        subscriptions[2] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            LIQUIDITY_COMMITTED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        // Remittance event subscription - tracks fee revenue remittances to fiscal policy
        subscriptions[3] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            REMITTANCE_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        return subscriptions;
    }
}