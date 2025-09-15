# Batched Low-Level Calls Libraries for Solidity

## Overview
This document lists the best libraries for handling batched low-level calls in Solidity, based on GitHub search results and community usage.

## Top Recommendations

### 1. Multicall3 (Most Popular)
- **Repository**: [Uniswap/v3-periphery](https://github.com/Uniswap/v3-periphery)
- **Contract**: `Multicall3.sol`
- **Features**:
  - Supports `aggregate3` for batched calls with return data
  - Gas-efficient implementation
  - Widely adopted in the ecosystem
  - Supports both `call` and `delegatecall`

### 2. OpenZeppelin Multicall
- **Repository**: [OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- **Contract**: `utils/Multicall.sol`
- **Features**:
  - Part of the trusted OpenZeppelin library
  - Simple and secure implementation
  - Good for basic multicall needs

### 3. Solady Multicall
- **Repository**: [Vectorized/solady](https://github.com/Vectorized/solady)
- **Contract**: `utils/Multicallable.sol`
- **Features**:
  - Gas-optimized implementation
  - Modern Solidity patterns
- **Note**: This is a fork of Solmate, not the original

### 4. Solmate Multicall
- **Repository**: [Rari-Capital/solmate](https://github.com/Rari-Capital/solmate)
- **Contract**: `utils/Multicall.sol`
- **Features**:
  - Gas-efficient implementation
  - Clean, minimal code
  - Good for advanced users

## Implementation Examples

### Basic Multicall Implementation
```solidity
// Simple multicall contract
contract Multicall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                // Handle failure
                revert("Multicall failed");
            }
            results[i] = result;
        }
    }
}
```

### Advanced Multicall with Error Handling
```solidity
// Multicall with individual call success tracking
contract AdvancedMulticall {
    struct Call {
        address target;
        bytes data;
    }
    
    struct Result {
        bool success;
        bytes returnData;
    }
    
    function multicall(Call[] calldata calls) external returns (Result[] memory results) {
        results = new Result[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (bool success, bytes memory returnData) = calls[i].target.call(calls[i].data);
            results[i] = Result(success, returnData);
        }
    }
}
```

## Usage Recommendations

1. **For Production**: Use Multicall3 or OpenZeppelin's implementation
2. **For Gas Optimization**: Consider Solady or Solmate
3. **For Learning**: Start with OpenZeppelin's simple implementation

## Installation

### Using Foundry
```bash
# For Multicall3
forge install Uniswap/v3-periphery

# For OpenZeppelin
forge install OpenZeppelin/openzeppelin-contracts

# For Solady
forge install Vectorized/solady
```

### Using Hardhat
```bash
npm install @openzeppelin/contracts
npm install @uniswap/v3-periphery
```

## Security Considerations

1. **Reentrancy**: Be aware of reentrancy attacks when using delegatecall
2. **Gas Limits**: Large batches may hit gas limits
3. **Error Handling**: Implement proper error handling for failed calls
4. **Access Control**: Consider who can call the multicall function

## References

- [Uniswap v3 Periphery](https://github.com/Uniswap/v3-periphery)
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Solady](https://github.com/Vectorized/solady)
- [Solmate](https://github.com/Rari-Capital/solmate)
