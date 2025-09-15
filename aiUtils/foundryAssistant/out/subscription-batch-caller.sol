// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IParityTaxHook} from "../src/interfaces/IParityTaxHook.sol";
import {ParityTaxHookSubscriptions} from "../src/libraries/ParityTaxHookSubscriptions.sol";

/**
 * @title SubscriptionBatchCaller
 * @dev Specialized library for batch calling subscription functions using ParityTaxHookSubscriptions
 * @notice This library takes the bytes[] from ParityTaxHookSubscriptions and executes them as batch calls
 */
library SubscriptionBatchCaller {
    
    struct SubscriptionResult {
        bool success;       // Whether the subscription call succeeded
        bytes returnData;   // Return data from the subscription call
        uint256 gasUsed;    // Gas used for this subscription call
    }
    
    struct BatchSubscriptionResult {
        bool[] successes;           // Array of success statuses for all subscriptions
        bytes[] returnDataArray;    // Array of return data for all subscriptions
        uint256[] gasUsedArray;     // Array of gas used for each subscription
        uint256 totalGasUsed;       // Total gas used for all subscriptions
        uint256 successCount;       // Number of successful subscriptions
    }
    
    /**
     * @dev Execute batch subscription calls using ParityTaxHookSubscriptions
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @return result BatchSubscriptionResult containing all results
     */
    function batchExecuteSubscriptions(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget
    ) external returns (BatchSubscriptionResult memory result) {
        // Get subscription bytes from ParityTaxHookSubscriptions
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize result arrays
        result.successes = new bool[](subscriptions.length);
        result.returnDataArray = new bytes[](subscriptions.length);
        result.gasUsedArray = new uint256[](subscriptions.length);
        
        uint256 totalGasUsed = 0;
        uint256 successCount = 0;
        
        // Execute each subscription
        for (uint256 i = 0; i < subscriptions.length; i++) {
            uint256 gasStart = gasleft();
            
            (bool success, bytes memory returnData) = _subscriptionTarget.call(subscriptions[i]);
            
            uint256 gasUsed = gasStart - gasleft();
            
            result.successes[i] = success;
            result.returnDataArray[i] = returnData;
            result.gasUsedArray[i] = gasUsed;
            
            totalGasUsed += gasUsed;
            if (success) {
                successCount++;
            }
        }
        
        result.totalGasUsed = totalGasUsed;
        result.successCount = successCount;
    }
    
    /**
     * @dev Execute batch subscription calls with gas limit per call
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @param _gasLimitPerCall Maximum gas per subscription call
     * @return result BatchSubscriptionResult containing all results
     */
    function batchExecuteSubscriptionsWithGasLimit(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget,
        uint256 _gasLimitPerCall
    ) external returns (BatchSubscriptionResult memory result) {
        // Get subscription bytes from ParityTaxHookSubscriptions
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize result arrays
        result.successes = new bool[](subscriptions.length);
        result.returnDataArray = new bytes[](subscriptions.length);
        result.gasUsedArray = new uint256[](subscriptions.length);
        
        uint256 totalGasUsed = 0;
        uint256 successCount = 0;
        
        // Execute each subscription with gas limit
        for (uint256 i = 0; i < subscriptions.length; i++) {
            uint256 gasStart = gasleft();
            
            // Ensure we don't exceed the gas limit
            uint256 availableGas = _gasLimitPerCall < gasleft() ? _gasLimitPerCall : gasleft();
            
            (bool success, bytes memory returnData) = _subscriptionTarget.call{gas: availableGas}(subscriptions[i]);
            
            uint256 gasUsed = gasStart - gasleft();
            
            result.successes[i] = success;
            result.returnDataArray[i] = returnData;
            result.gasUsedArray[i] = gasUsed;
            
            totalGasUsed += gasUsed;
            if (success) {
                successCount++;
            }
        }
        
        result.totalGasUsed = totalGasUsed;
        result.successCount = successCount;
    }
    
    /**
     * @dev Execute batch subscription calls with error handling (continues on failure)
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @return result BatchSubscriptionResult containing all results
     */
    function batchExecuteSubscriptionsWithErrorHandling(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget
    ) external returns (BatchSubscriptionResult memory result) {
        // Get subscription bytes from ParityTaxHookSubscriptions
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize result arrays
        result.successes = new bool[](subscriptions.length);
        result.returnDataArray = new bytes[](subscriptions.length);
        result.gasUsedArray = new uint256[](subscriptions.length);
        
        uint256 totalGasUsed = 0;
        uint256 successCount = 0;
        
        // Execute each subscription with error handling
        for (uint256 i = 0; i < subscriptions.length; i++) {
            uint256 gasStart = gasleft();
            
            try this.executeSubscriptionCall(_subscriptionTarget, subscriptions[i]) returns (bytes memory returnData) {
                uint256 gasUsed = gasStart - gasleft();
                result.successes[i] = true;
                result.returnDataArray[i] = returnData;
                result.gasUsedArray[i] = gasUsed;
                successCount++;
            } catch {
                uint256 gasUsed = gasStart - gasleft();
                result.successes[i] = false;
                result.returnDataArray[i] = "";
                result.gasUsedArray[i] = gasUsed;
            }
            
            totalGasUsed += result.gasUsedArray[i];
        }
        
        result.totalGasUsed = totalGasUsed;
        result.successCount = successCount;
    }
    
    /**
     * @dev Internal function to execute a single subscription call (used by try/catch)
     * @param _target The target contract address
     * @param _data The subscription call data
     * @return returnData The return data from the call
     */
    function executeSubscriptionCall(address _target, bytes calldata _data) external returns (bytes memory returnData) {
        (bool success, bytes memory data) = _target.call(_data);
        require(success, "Subscription call failed");
        return data;
    }
    
    /**
     * @dev Get subscription bytes without executing them
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @return subscriptions Array of subscription bytes
     */
    function getSubscriptionBytes(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId
    ) external pure returns (bytes[] memory subscriptions) {
        return ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
    }
}

/**
 * @title ParityTaxSubscriptionManager
 * @dev Contract that uses the SubscriptionBatchCaller library
 * @notice This contract manages batch subscription calls for ParityTax hooks
 */
contract ParityTaxSubscriptionManager {
    using SubscriptionBatchCaller for IParityTaxHook;
    
    event SubscriptionsExecuted(
        uint256 indexed batchId,
        address indexed parityTaxHook,
        uint256 chainId,
        uint256 successCount,
        uint256 totalSubscriptions,
        uint256 totalGasUsed
    );
    
    uint256 public batchIdCounter;
    
    /**
     * @dev Execute batch subscriptions for a ParityTax hook
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @return result BatchSubscriptionResult containing all results
     */
    function executeBatchSubscriptions(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget
    ) external returns (SubscriptionBatchCaller.BatchSubscriptionResult memory result) {
        result = SubscriptionBatchCaller.batchExecuteSubscriptions(_parityTaxHook, _chainId, _subscriptionTarget);
        
        emit SubscriptionsExecuted(
            batchIdCounter++,
            address(_parityTaxHook),
            _chainId,
            result.successCount,
            result.successes.length,
            result.totalGasUsed
        );
        
        return result;
    }
    
    /**
     * @dev Execute batch subscriptions with gas limit
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @param _gasLimitPerCall Maximum gas per subscription call
     * @return result BatchSubscriptionResult containing all results
     */
    function executeBatchSubscriptionsWithGasLimit(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget,
        uint256 _gasLimitPerCall
    ) external returns (SubscriptionBatchCaller.BatchSubscriptionResult memory result) {
        result = SubscriptionBatchCaller.batchExecuteSubscriptionsWithGasLimit(
            _parityTaxHook,
            _chainId,
            _subscriptionTarget,
            _gasLimitPerCall
        );
        
        emit SubscriptionsExecuted(
            batchIdCounter++,
            address(_parityTaxHook),
            _chainId,
            result.successCount,
            result.successes.length,
            result.totalGasUsed
        );
        
        return result;
    }
    
    /**
     * @dev Execute batch subscriptions with error handling
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @return result BatchSubscriptionResult containing all results
     */
    function executeBatchSubscriptionsWithErrorHandling(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget
    ) external returns (SubscriptionBatchCaller.BatchSubscriptionResult memory result) {
        result = SubscriptionBatchCaller.batchExecuteSubscriptionsWithErrorHandling(
            _parityTaxHook,
            _chainId,
            _subscriptionTarget
        );
        
        emit SubscriptionsExecuted(
            batchIdCounter++,
            address(_parityTaxHook),
            _chainId,
            result.successCount,
            result.successes.length,
            result.totalGasUsed
        );
        
        return result;
    }
    
    /**
     * @dev Get subscription bytes for a ParityTax hook
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @return subscriptions Array of subscription bytes
     */
    function getSubscriptionBytes(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId
    ) external pure returns (bytes[] memory subscriptions) {
        return SubscriptionBatchCaller.getSubscriptionBytes(_parityTaxHook, _chainId);
    }
}
