// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import {ParityTaxHookSubscriptions} from "./ParityTaxHookSubscriptions.sol";

/**
 * @title SimpleSubscriptionBatch
 * @dev Simplified library for batch calling subscription functions
 * @notice Returns bool (true if all succeed, reverts otherwise) and bytes[] return data
 */
library SubscriptionBatchCall {

    /**
     * @dev Execute batch subscription calls - reverts if any fail
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @return success Always true if all subscriptions succeed (reverts otherwise)
     * @return returnDataArray Array of return data from all subscriptions
     */
    function batchExecuteSubscriptions(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget
    ) external returns (bool success, bytes[] memory returnDataArray) {
        // Get subscription bytes from ParityTaxHookSubscriptions
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize return data array
        returnDataArray = new bytes[](subscriptions.length);
        
        // Execute each subscription - revert if any fail
        for (uint256 i = 0; i < subscriptions.length; i++) {
            (bool callSuccess, bytes memory returnData) = _subscriptionTarget.call(subscriptions[i]);
            
            require(callSuccess, string(abi.encodePacked("Subscription ", i, " failed")));
            
            returnDataArray[i] = returnData;
        }
        
        // All subscriptions succeeded
        success = true;
    }
    
    /**
     * @dev Execute batch subscription calls with gas limit - reverts if any fail
     * @param _parityTaxHook The ParityTaxHook contract address
     * @param _chainId The chain ID for subscriptions
     * @param _subscriptionTarget The target contract to call for subscriptions
     * @param _gasLimitPerCall Maximum gas per subscription call
     * @return success Always true if all subscriptions succeed (reverts otherwise)
     * @return returnDataArray Array of return data from all subscriptions
     */
    function batchExecuteSubscriptionsWithGasLimit(
        IParityTaxHook _parityTaxHook,
        uint256 _chainId,
        address _subscriptionTarget,
        uint256 _gasLimitPerCall
    ) external returns (bool success, bytes[] memory returnDataArray) {
        // Get subscription bytes from ParityTaxHookSubscriptions
        bytes[] memory subscriptions = ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
        
        // Initialize return data array
        returnDataArray = new bytes[](subscriptions.length);
        
        // Execute each subscription with gas limit - revert if any fail
        for (uint256 i = 0; i < subscriptions.length; i++) {
            // Ensure we don't exceed the gas limit
            uint256 availableGas = _gasLimitPerCall < gasleft() ? _gasLimitPerCall : gasleft();
            
            (bool callSuccess, bytes memory returnData) = _subscriptionTarget.call{gas: availableGas}(subscriptions[i]);
            
            require(callSuccess, string(abi.encodePacked("Subscription ", i, " failed with gas limit")));
            
            returnDataArray[i] = returnData;
        }
        
        // All subscriptions succeeded
        success = true;
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
    ) external view returns (bytes[] memory subscriptions) {
        return ParityTaxHookSubscriptions.getSubscriptions(_parityTaxHook, _chainId);
    }
}
