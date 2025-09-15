// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../subscription-batch-caller.sol";

/**
 * @title TestSubscriptionBatch
 * @dev Foundry script to test the subscription batch calling functionality
 */
contract TestSubscriptionBatch is Script {
    
    function run() external {
        console.log("=== Testing Subscription Batch Caller ===");
        
        // Mock ParityTaxHook for testing
        address mockParityTaxHook = address(0x1234567890123456789012345678901234567890);
        uint256 chainId = 1;
        address subscriptionTarget = address(0x9876543210987654321098765432109876543210);
        
        console.log("Mock ParityTaxHook:", mockParityTaxHook);
        console.log("Chain ID:", chainId);
        console.log("Subscription Target:", subscriptionTarget);
        
        // Test getting subscription bytes
        console.log("\n--- Getting Subscription Bytes ---");
        bytes[] memory subscriptions = SubscriptionBatchCaller.getSubscriptionBytes(
            IParityTaxHook(mockParityTaxHook),
            chainId
        );
        
        console.log("Number of subscriptions:", subscriptions.length);
        
        for (uint256 i = 0; i < subscriptions.length; i++) {
            console.log("Subscription %d length:", i, subscriptions[i].length);
            console.log("Subscription %d data:", i);
            console.logBytes(subscriptions[i]);
        }
        
        // Test batch execution (this will fail since we're using mock addresses)
        console.log("\n--- Testing Batch Execution ---");
        console.log("Note: This will fail with mock addresses, but shows the structure");
        
        try SubscriptionBatchCaller.batchExecuteSubscriptions(
            IParityTaxHook(mockParityTaxHook),
            chainId,
            subscriptionTarget
        ) returns (SubscriptionBatchCaller.BatchSubscriptionResult memory result) {
            console.log("Success count:", result.successCount);
            console.log("Total subscriptions:", result.successes.length);
            console.log("Total gas used:", result.totalGasUsed);
            
            for (uint256 i = 0; i < result.successes.length; i++) {
                console.log("Subscription %d success:", i, result.successes[i]);
                console.log("Subscription %d gas used:", i, result.gasUsedArray[i]);
            }
        } catch Error(string memory reason) {
            console.log("Expected error with mock addresses:", reason);
        } catch {
            console.log("Unexpected error occurred");
        }
        
        console.log("\n=== Test Complete ===");
    }
    
    /**
     * @dev Test the subscription bytes structure
     */
    function testSubscriptionStructure() external pure {
        address mockParityTaxHook = address(0x1234567890123456789012345678901234567890);
        uint256 chainId = 1;
        
        bytes[] memory subscriptions = SubscriptionBatchCaller.getSubscriptionBytes(
            IParityTaxHook(mockParityTaxHook),
            chainId
        );
        
        // Verify we have 4 subscriptions (based on NUMBER_EVENTS = 0x04)
        require(subscriptions.length == 4, "Should have 4 subscriptions");
        
        // Each subscription should be a call to subscribe function
        for (uint256 i = 0; i < subscriptions.length; i++) {
            require(subscriptions[i].length > 0, "Subscription should not be empty");
            // The first 4 bytes should be the function selector for subscribe
            bytes4 selector = bytes4(subscriptions[i][0:4]);
            require(selector == bytes4(keccak256("subscribe(uint256,address,uint256,uint256,uint256,uint256)")), "Should be subscribe function");
        }
    }
}
