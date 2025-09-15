// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./batch-external-calls.sol";

/**
 * @title ParityTaxBatchExample
 * @dev Example showing how to use batch external calls for ParityTax hook operations
 */
contract ParityTaxBatchExample {
    using BatchExternalCalls for BatchExternalCalls.Call;
    
    // Example: Batch call multiple external contracts for fee collection
    function batchCollectFees(
        address[] calldata feeCollectors,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external returns (BatchExternalCalls.Result[] memory results) {
        require(feeCollectors.length == tokens.length, "Arrays length mismatch");
        require(tokens.length == amounts.length, "Arrays length mismatch");
        
        BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](feeCollectors.length);
        
        for (uint256 i = 0; i < feeCollectors.length; i++) {
            // Encode transfer function call for ERC20 token
            calls[i] = BatchExternalCalls.Call({
                target: tokens[i],
                value: 0, // No ETH value for ERC20 transfers
                data: abi.encodeWithSignature("transfer(address,uint256)", feeCollectors[i], amounts[i])
            });
        }
        
        return BatchExternalCalls.batchCall(calls);
    }
    
    // Example: Batch call multiple hooks for event subscription
    function batchSubscribeToHooks(
        address[] calldata hookAddresses,
        uint256 chainId
    ) external returns (BatchExternalCalls.Result[] memory results) {
        BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](hookAddresses.length);
        
        for (uint256 i = 0; i < hookAddresses.length; i++) {
            // Encode subscription call (assuming the hook has a subscribe function)
            calls[i] = BatchExternalCalls.Call({
                target: hookAddresses[i],
                value: 0,
                data: abi.encodeWithSignature("subscribe(uint256)", chainId)
            });
        }
        
        return BatchExternalCalls.batchCall(calls);
    }
    
    // Example: Batch call for getting data from multiple sources
    function batchGetData(
        address[] calldata dataSources,
        bytes4[] calldata functionSelectors
    ) external returns (BatchExternalCalls.Result[] memory results) {
        require(dataSources.length == functionSelectors.length, "Arrays length mismatch");
        
        BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](dataSources.length);
        
        for (uint256 i = 0; i < dataSources.length; i++) {
            calls[i] = BatchExternalCalls.Call({
                target: dataSources[i],
                value: 0,
                data: abi.encodeWithSelector(functionSelectors[i])
            });
        }
        
        return BatchExternalCalls.batchCall(calls);
    }
    
    // Example: Batch call with different function signatures
    function batchMixedCalls(
        address[] calldata targets,
        bytes[] calldata callData
    ) external returns (BatchExternalCalls.Result[] memory results) {
        require(targets.length == callData.length, "Arrays length mismatch");
        
        BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](targets.length);
        
        for (uint256 i = 0; i < targets.length; i++) {
            calls[i] = BatchExternalCalls.Call({
                target: targets[i],
                value: 0,
                data: callData[i]
            });
        }
        
        return BatchExternalCalls.batchCall(calls);
    }
}
