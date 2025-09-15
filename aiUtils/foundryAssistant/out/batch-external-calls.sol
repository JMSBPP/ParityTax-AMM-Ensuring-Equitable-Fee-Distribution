// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BatchExternalCalls
 * @dev Library for making batch low-level calls to external contracts
 * @notice This allows you to call multiple functions on external contracts in a single transaction
 */
library BatchExternalCalls {
    
    struct Call {
        address target;     // Contract address to call
        uint256 value;      // ETH value to send (0 for most calls)
        bytes data;         // Encoded function call data
    }
    
    struct Result {
        bool success;       // Whether the call succeeded
        bytes returnData;   // Return data from the call
        uint256 gasUsed;    // Gas used for this call
    }
    
    /**
     * @dev Execute multiple calls to external contracts
     * @param calls Array of Call structs containing target, value, and data
     * @return results Array of Result structs with success status and return data
     */
    function batchCall(Call[] calldata calls) external returns (Result[] memory results) {
        results = new Result[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 gasStart = gasleft();
            
            (bool success, bytes memory returnData) = calls[i].target.call{value: calls[i].value}(calls[i].data);
            
            uint256 gasUsed = gasStart - gasleft();
            
            results[i] = Result({
                success: success,
                returnData: returnData,
                gasUsed: gasUsed
            });
        }
    }
    
    /**
     * @dev Execute multiple calls with gas limit per call
     * @param calls Array of Call structs
     * @param gasLimitPerCall Maximum gas to use per call
     * @return results Array of Result structs
     */
    function batchCallWithGasLimit(
        Call[] calldata calls, 
        uint256 gasLimitPerCall
    ) external returns (Result[] memory results) {
        results = new Result[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 gasStart = gasleft();
            
            // Ensure we don't exceed the gas limit
            uint256 availableGas = gasLimitPerCall < gasleft() ? gasLimitPerCall : gasleft();
            
            (bool success, bytes memory returnData) = calls[i].target.call{value: calls[i].value, gas: availableGas}(calls[i].data);
            
            uint256 gasUsed = gasStart - gasleft();
            
            results[i] = Result({
                success: success,
                returnData: returnData,
                gasUsed: gasUsed
            });
        }
    }
    
    /**
     * @dev Execute calls with individual error handling (continues on failure)
     * @param calls Array of Call structs
     * @return results Array of Result structs
     */
    function batchCallWithErrorHandling(Call[] calldata calls) external returns (Result[] memory results) {
        results = new Result[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 gasStart = gasleft();
            
            try this.executeCall(calls[i]) returns (bytes memory returnData) {
                uint256 gasUsed = gasStart - gasleft();
                results[i] = Result({
                    success: true,
                    returnData: returnData,
                    gasUsed: gasUsed
                });
            } catch {
                uint256 gasUsed = gasStart - gasleft();
                results[i] = Result({
                    success: false,
                    returnData: "",
                    gasUsed: gasUsed
                });
            }
        }
    }
    
    /**
     * @dev Internal function to execute a single call (used by try/catch)
     * @param call The call to execute
     * @return returnData The return data from the call
     */
    function executeCall(Call calldata call) external returns (bytes memory returnData) {
        (bool success, bytes memory data) = call.target.call{value: call.value}(call.data);
        require(success, "Call failed");
        return data;
    }
    
    /**
     * @dev Execute calls with delegatecall (calls execute in the context of this contract)
     * @param calls Array of Call structs
     * @return results Array of Result structs
     */
    function batchDelegateCall(Call[] calldata calls) external returns (Result[] memory results) {
        results = new Result[](calls.length);
        
        for (uint256 i = 0; i < calls.length; i++) {
            uint256 gasStart = gasleft();
            
            (bool success, bytes memory returnData) = calls[i].target.delegatecall(calls[i].data);
            
            uint256 gasUsed = gasStart - gasleft();
            
            results[i] = Result({
                success: success,
                returnData: returnData,
                gasUsed: gasUsed
            });
        }
    }
}

/**
 * @title BatchCaller
 * @dev Contract that uses the BatchExternalCalls library
 * @notice This is an example contract showing how to use the batch calling functionality
 */
contract BatchCaller {
    using BatchExternalCalls for BatchExternalCalls.Call;
    
    event BatchCallExecuted(uint256 indexed batchId, uint256 successCount, uint256 totalCalls);
    
    uint256 public batchIdCounter;
    
    /**
     * @dev Execute a batch of calls and emit results
     * @param calls Array of calls to execute
     * @return results Array of results
     */
    function executeBatch(BatchExternalCalls.Call[] calldata calls) external returns (BatchExternalCalls.Result[] memory results) {
        results = BatchExternalCalls.batchCall(calls);
        
        uint256 successCount = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].success) {
                successCount++;
            }
        }
        
        emit BatchCallExecuted(batchIdCounter++, successCount, calls.length);
        
        return results;
    }
    
    /**
     * @dev Execute batch calls with gas limit
     * @param calls Array of calls to execute
     * @param gasLimitPerCall Maximum gas per call
     * @return results Array of results
     */
    function executeBatchWithGasLimit(
        BatchExternalCalls.Call[] calldata calls,
        uint256 gasLimitPerCall
    ) external returns (BatchExternalCalls.Result[] memory results) {
        results = BatchExternalCalls.batchCallWithGasLimit(calls, gasLimitPerCall);
        
        uint256 successCount = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].success) {
                successCount++;
            }
        }
        
        emit BatchCallExecuted(batchIdCounter++, successCount, calls.length);
        
        return results;
    }
    
    /**
     * @dev Execute batch calls with error handling
     * @param calls Array of calls to execute
     * @return results Array of results
     */
    function executeBatchWithErrorHandling(
        BatchExternalCalls.Call[] calldata calls
    ) external returns (BatchExternalCalls.Result[] memory results) {
        results = BatchExternalCalls.batchCallWithErrorHandling(calls);
        
        uint256 successCount = 0;
        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].success) {
                successCount++;
            }
        }
        
        emit BatchCallExecuted(batchIdCounter++, successCount, calls.length);
        
        return results;
    }
}
