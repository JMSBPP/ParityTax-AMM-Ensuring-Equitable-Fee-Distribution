# Batch External Calls Library

## Overview
This library allows you to make batch low-level calls to external contracts that don't inherit any multicall functionality. It's perfect for calling multiple external contracts in a single transaction.

## Key Features

### 1. **BatchExternalCalls Library**
- **`batchCall()`**: Execute multiple calls to external contracts
- **`batchCallWithGasLimit()`**: Execute calls with gas limit per call
- **`batchCallWithErrorHandling()`**: Continue execution even if some calls fail
- **`batchDelegateCall()`**: Execute calls using delegatecall

### 2. **Call Structure**
```solidity
struct Call {
    address target;     // Contract address to call
    uint256 value;      // ETH value to send (0 for most calls)
    bytes data;         // Encoded function call data
}
```

### 3. **Result Structure**
```solidity
struct Result {
    bool success;       // Whether the call succeeded
    bytes returnData;   // Return data from the call
    uint256 gasUsed;    // Gas used for this call
}
```

## Usage Examples

### Basic Batch Call
```solidity
import "./batch-external-calls.sol";

contract MyContract {
    using BatchExternalCalls for BatchExternalCalls.Call;
    
    function batchTransfer(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](tokens.length);
        
        for (uint256 i = 0; i < tokens.length; i++) {
            calls[i] = BatchExternalCalls.Call({
                target: tokens[i],
                value: 0,
                data: abi.encodeWithSignature("transfer(address,uint256)", recipients[i], amounts[i])
            });
        }
        
        BatchExternalCalls.Result[] memory results = BatchExternalCalls.batchCall(calls);
        
        // Process results
        for (uint256 i = 0; i < results.length; i++) {
            require(results[i].success, "Transfer failed");
        }
    }
}
```

### Batch Call with Error Handling
```solidity
function batchCallWithErrors(
    address[] calldata targets,
    bytes[] calldata callData
) external {
    BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](targets.length);
    
    for (uint256 i = 0; i < targets.length; i++) {
        calls[i] = BatchExternalCalls.Call({
            target: targets[i],
            value: 0,
            data: callData[i]
        });
    }
    
    BatchExternalCalls.Result[] memory results = BatchExternalCalls.batchCallWithErrorHandling(calls);
    
    // Process results - some may have failed
    for (uint256 i = 0; i < results.length; i++) {
        if (results[i].success) {
            // Handle successful call
            console.log("Call %d succeeded", i);
        } else {
            // Handle failed call
            console.log("Call %d failed", i);
        }
    }
}
```

### Batch Call with Gas Limit
```solidity
function batchCallWithGasLimit(
    address[] calldata targets,
    bytes[] calldata callData,
    uint256 gasLimitPerCall
) external {
    BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](targets.length);
    
    for (uint256 i = 0; i < targets.length; i++) {
        calls[i] = BatchExternalCalls.Call({
            target: targets[i],
            value: 0,
            data: callData[i]
        });
    }
    
    BatchExternalCalls.Result[] memory results = BatchExternalCalls.batchCallWithGasLimit(calls, gasLimitPerCall);
    
    // Process results
    for (uint256 i = 0; i < results.length; i++) {
        console.log("Call %d: success=%s, gasUsed=%d", i, results[i].success, results[i].gasUsed);
    }
}
```

## Advanced Usage Patterns

### 1. **Mixed Function Calls**
```solidity
function batchMixedCalls() external {
    BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](3);
    
    // Call 1: ERC20 transfer
    calls[0] = BatchExternalCalls.Call({
        target: tokenAddress,
        value: 0,
        data: abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
    });
    
    // Call 2: Contract function with parameters
    calls[1] = BatchExternalCalls.Call({
        target: contractAddress,
        value: 0,
        data: abi.encodeWithSignature("setValue(uint256)", newValue)
    });
    
    // Call 3: Function with multiple parameters
    calls[2] = BatchExternalCalls.Call({
        target: anotherContract,
        value: 0,
        data: abi.encodeWithSignature("updateData(address,uint256,bytes32)", addr, num, hash)
    });
    
    BatchExternalCalls.Result[] memory results = BatchExternalCalls.batchCall(calls);
}
```

### 2. **Batch Delegate Calls**
```solidity
function batchDelegateCalls(
    address[] calldata targets,
    bytes[] calldata callData
) external {
    BatchExternalCalls.Call[] memory calls = new BatchExternalCalls.Call[](targets.length);
    
    for (uint256 i = 0; i < targets.length; i++) {
        calls[i] = BatchExternalCalls.Call({
            target: targets[i],
            value: 0,
            data: callData[i]
        });
    }
    
    BatchExternalCalls.Result[] memory results = BatchExternalCalls.batchDelegateCall(calls);
}
```

## Gas Optimization Tips

1. **Use `batchCallWithGasLimit()`** to prevent individual calls from consuming too much gas
2. **Use `batchCallWithErrorHandling()`** to continue execution even if some calls fail
3. **Batch similar operations** together to reduce transaction overhead
4. **Consider gas costs** when batching large numbers of calls

## Security Considerations

1. **Reentrancy**: Be aware of reentrancy attacks when using delegatecall
2. **Gas Limits**: Large batches may hit block gas limits
3. **Error Handling**: Implement proper error handling for failed calls
4. **Access Control**: Consider who can call the batch functions
5. **Input Validation**: Validate all inputs before making calls

## Integration with ParityTax Hook

This library is perfect for your ParityTax hook because you can:

1. **Batch fee collections** from multiple sources
2. **Batch event subscriptions** to multiple hooks
3. **Batch data retrieval** from multiple oracles
4. **Batch state updates** across multiple contracts

## Files Created

1. **`batch-external-calls.sol`**: Core library implementation
2. **`parity-tax-batch-example.sol`**: Example usage for ParityTax hook
3. **`batch-external-calls-guide.md`**: This documentation

## Next Steps

1. Copy the library to your project
2. Import it in your contracts
3. Use the examples as templates
4. Customize for your specific needs
5. Test thoroughly before deployment
