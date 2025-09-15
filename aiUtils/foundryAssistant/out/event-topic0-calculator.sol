//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Event Topic0 Calculator
 * @notice Script to calculate topic0 values for events in IParityTaxHook.sol
 * @dev Run with: forge script aiUtils/foundryAssistant/out/event-topic0-calculator.sol --sig "run()"
 */

contract EventTopic0Calculator {
    
    function run() external pure {
        // Event signatures from IParityTaxHook.sol
        string memory priceImpactSig = "PriceImpact(bytes32,uint48,SwapIntent,BalanceDelta,uint160,uint160,uint160,uint160)";
        string memory liquidityOnSwapSig = "LiquidityOnSwap(bytes32,uint48,uint128,uint128,uint128)";
        string memory liquidityCommittedSig = "LiquidityCommitted(bytes32,uint48,uint48,address,uint256,bytes)";
        string memory remittanceSig = "Remittance(bytes32,uint48,uint48,BalanceDelta)";
        
        // Calculate topic0 values
        bytes32 priceImpactTopic0 = keccak256(abi.encodePacked(priceImpactSig));
        bytes32 liquidityOnSwapTopic0 = keccak256(abi.encodePacked(liquidityOnSwapSig));
        bytes32 liquidityCommittedTopic0 = keccak256(abi.encodePacked(liquidityCommittedSig));
        bytes32 remittanceTopic0 = keccak256(abi.encodePacked(remittanceSig));
        
        // Output results
        console.log("=== IParityTaxHook.sol Event Topic0 Values ===");
        console.log("");
        console.log("Event: PriceImpact");
        console.log("Signature:", priceImpactSig);
        console.log("Topic0: 0x%x", uint256(priceImpactTopic0));
        console.log("");
        
        console.log("Event: LiquidityOnSwap");
        console.log("Signature:", liquidityOnSwapSig);
        console.log("Topic0: 0x%x", uint256(liquidityOnSwapTopic0));
        console.log("");
        
        console.log("Event: LiquidityCommitted");
        console.log("Signature:", liquidityCommittedSig);
        console.log("Topic0: 0x%x", uint256(liquidityCommittedTopic0));
        console.log("");
        
        console.log("Event: Remittance");
        console.log("Signature:", remittanceSig);
        console.log("Topic0: 0x%x", uint256(remittanceTopic0));
        console.log("");
        
        console.log("=== Summary ===");
        console.log("Total events found: 4");
        console.log("Note: LiquidityCommitted is marked as anonymous");
    }
}

// Import console for logging
import "forge-std/console.sol";
