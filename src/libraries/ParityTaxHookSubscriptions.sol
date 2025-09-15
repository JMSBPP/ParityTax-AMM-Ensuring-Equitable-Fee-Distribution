// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
//TODO Topics of all events

uint256 constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
//PriceImpact(bytes32,uint48,SwapIntent,BalanceDelta,uint160,uint160,uint160,uint160)
uint256 constant PRICE_IMPACT_TOPIC0 = 0x5893daed40175f5b967e0d8330bb4645462baa4dd943a1d477970a09005d0eba;
//LiquidityOnSwap(bytes32,uint48,uint128,uint128,uint128)
uint256 constant LIQUIDITY_ON_SWAP_TOPIC0 = 0xc8880b3ae9558df3a51b833923827bbd2f9ba44a9e301b9fc30c9ebc9b74f98a;
// LiquidityCommitted(bytes32,uint48,uint48,address,uint256,bytes)
uint256 constant LIQUIDITY_COMMITTED_TOPIC0 = 0xcec8de8a7601b90797cedff00dcb85732045825d1bf02308be5874f59bc616d4;

// Remittance(bytes32,uint48,uint48,BalanceDelta)
uint256 constant REMITTANCE_TOPIC0 = 0x58dfacde9fc85654a0cc8143d1b2311ae404acab04d626a660c0a45db26c891c;

uint256 constant NUMBER_EVENTS = uint256(0x04);


library ParityTaxHookSubscriptions{
     

    function getSubscriptions(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId
    ) internal view returns(bytes[] memory){
        
        bytes[] memory subscriptions = new bytes[](NUMBER_EVENTS);
        
        // PriceImpact event subscription
        subscriptions[0] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            PRICE_IMPACT_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        // LiquidityOnSwap event subscription
        subscriptions[1] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            LIQUIDITY_ON_SWAP_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        // LiquidityCommitted event subscription
        subscriptions[2] = abi.encodeWithSignature(
            "subscribe(uint256,address,uint256,uint256,uint256,uint256)",
            _chainId,
            address(_parityTaxHook),
            LIQUIDITY_COMMITTED_TOPIC0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        
        // Remittance event subscription
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