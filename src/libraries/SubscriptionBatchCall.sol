// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import {ParityTaxHookSubscriptions} from "./ParityTaxHookSubscriptions.sol";

/**
 * @title SubscriptionBatchCall
 * @author ParityTax Team
 * @notice Library for batch execution of ParityTax hook subscriptions in the reactive network
 * @dev This library is a critical component of the reactive network architecture, responsible for
 * managing and executing batch subscriptions to ParityTax hook events. It enables the FiscalListeningPost
 * to efficiently subscribe to multiple events from the ParityTax hook system and execute them in batch
 * operations for optimal gas efficiency and real-time event processing.
 * @dev Provides both standard batch execution and gas-limited execution for different use cases
 */
library SubscriptionBatchCall {

    /**
     * @notice Executes batch subscription calls to ParityTax hook events
     * @dev This function retrieves all subscription data from ParityTaxHookSubscriptions and executes
     * them in batch against the target contract. It reverts if any subscription fails, ensuring
     * atomicity of the batch operation. This is used by FiscalListeningPost to set up reactive
     * network subscriptions to ParityTax hook events for real-time fiscal policy calculations.
     * @param _parityTaxHook The ParityTaxHook contract address to subscribe to events from
     * @param _chainId The blockchain chain ID for the reactive network subscriptions
     * @param _subscriptionTarget The target contract address (typically FiscalListeningPost) to execute subscriptions
     * @return success Always true if all subscriptions succeed (reverts otherwise)
     * @return returnDataArray Array of return data from all subscription calls
     */
    function batchExecuteSubscriptions(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget
    ) external returns (bool success, bytes[] memory returnDataArray) {
        // Get subscription bytes from ParityTaxHookSubscriptions library
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize return data array with the number of subscriptions
        returnDataArray = new bytes[](subscriptions.length);
        
        // Execute each subscription call - revert if any fail to ensure atomicity
        for (uint256 i = 0; i < subscriptions.length; i++) {
            (bool callSuccess, bytes memory returnData) = _subscriptionTarget.call(subscriptions[i]);
            
            require(callSuccess, string(abi.encodePacked("Subscription ", i, " failed")));
            
            returnDataArray[i] = returnData;
        }
        
        // All subscriptions succeeded - return true
        success = true;
    }
    
    /**
     * @notice Executes batch subscription calls with gas limit protection
     * @dev This function provides gas-limited execution of ParityTax hook subscriptions, useful for
     * scenarios where gas consumption needs to be controlled or when executing in environments with
     * limited gas availability. It ensures each subscription call doesn't exceed the specified gas limit
     * while maintaining atomicity of the batch operation.
     * @param _parityTaxHook The ParityTaxHook contract address to subscribe to events from
     * @param _chainId The blockchain chain ID for the reactive network subscriptions
     * @param _subscriptionTarget The target contract address (typically FiscalListeningPost) to execute subscriptions
     * @param _gasLimitPerCall Maximum gas allowed per individual subscription call
     * @return success Always true if all subscriptions succeed (reverts otherwise)
     * @return returnDataArray Array of return data from all subscription calls
     */
    function batchExecuteSubscriptionsWithGasLimit(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget,
        uint256 _gasLimitPerCall
    ) external returns (bool success, bytes[] memory returnDataArray) {
        // Get subscription bytes from ParityTaxHookSubscriptions library
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize return data array with the number of subscriptions
        returnDataArray = new bytes[](subscriptions.length);
        
        // Execute each subscription with gas limit protection - revert if any fail
        for (uint256 i = 0; i < subscriptions.length; i++) {
            // Calculate available gas, respecting both the per-call limit and remaining gas
            uint256 availableGas = _gasLimitPerCall < gasleft() ? _gasLimitPerCall : gasleft();
            
            (bool callSuccess, bytes memory returnData) = _subscriptionTarget.call{gas: availableGas}(subscriptions[i]);
            
            require(callSuccess, string(abi.encodePacked("Subscription ", i, " failed with gas limit")));
            
            returnDataArray[i] = returnData;
        }
        
        // All subscriptions succeeded - return true
        success = true;
    }
    
    /**
     * @notice Retrieves subscription bytes without executing them
     * @dev This view function allows inspection of subscription data before execution, useful for
     * debugging, gas estimation, or pre-validation of subscription calls. It delegates to the
     * ParityTaxHookSubscriptions library to get the raw subscription data for a given chain.
     * @param _parityTaxHook The ParityTaxHook contract address to get subscriptions for
     * @param _chainId The blockchain chain ID for the reactive network subscriptions
     * @return subscriptions Array of subscription bytes that would be executed
     */
    function getSubscriptionBytes(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId
    ) external view returns (bytes[] memory subscriptions) {
        return ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
    }
}

