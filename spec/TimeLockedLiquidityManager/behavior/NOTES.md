- A timeCommietment as three states:
  - **valid** (liquidytTimeCommitment > block.timeStamp)
  - **invalid** (liquidytTimeCommitment <= block.timeStamp)
  - **JIT** (liquidytTimeCommitment = JIT = type(uint256).max (__reserved value__))

- A liquidityLevel has two states:
  - **empty** (liquidityLevel =0)
  - **non-empty** (liquidityLevel > 0)
- Therefore a liquidityTimeCommittedPosition state is defined by a timeCommitment and a liquidityLevel
```solidity
struct PositionInfo{
    uint128 liquidityLevel;
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX12;
}

mapping(bytes32 liquidityPositionKey => TimeCommitment) liquidityTimeCommittedPosition;
bytes32 liquidityPositionKey = keccak256(abi.encode(address(liquidityRouter) ,liquidityParams.tickUpper,liquidityParams.tickLower,liquidityParams.salt));
```

```json
{
    "states": [
        {
            "name": "Active Committed Position",
            "description": "Time commitment is valid (future-dated) with active liquidity",
            "timeCommitmentState": "valid",
            "liquidityState": "non-empty",
            "notation": "liquidityTimeCommittedPosition[positionKey] > block.timestamp && positionInfo.liquidityLevel > 0",
            "withdrawable": false
        },
        {
            "name": "Expired Withdrawable Position",
            "description": "Time commitment has expired with no remaining liquidity",
            "timeCommitmentState": "invalid",
            "liquidityState": "empty",
            "notation": "liquidityTimeCommittedPosition[positionKey] <= block.timestamp && liquidityTimeCommittedPosition[positionKey] != type(uint256).max && positionInfo.liquidityLevel == 0",
            "withdrawable": true
        },
        {
            "name": "Expired Locked Position",
            "description": "Time commitment has expired but liquidity remains (requires withdrawal)",
            "timeCommitmentState": "invalid",
            "liquidityState": "non-empty",
            "notation": "liquidityTimeCommittedPosition[positionKey] <= block.timestamp && liquidityTimeCommittedPosition[positionKey] != type(uint256).max && positionInfo.liquidityLevel > 0",
            "withdrawable": false
        },
        {
            "name": "Committed Empty Position",
            "description": "Time commitment is valid but no liquidity exists (inconsistent state)",
            "timeCommitmentState": "valid",
            "liquidityState": "empty",
            "notation": "liquidityTimeCommittedPosition[positionKey] > block.timestamp && positionInfo.liquidityLevel == 0",
            "withdrawable": false,
            "status": "invalid"
        },
        {
            "name": "Active JIT Position",
            "description": "Just-in-Time liquidity with active funds (special unrestricted rules)",
            "timeCommitmentState": "JIT",
            "liquidityState": "non-empty",
            "notation": "liquidityTimeCommittedPosition[positionKey] == type(uint256).max && positionInfo.liquidityLevel > 0",
            "withdrawable": true
        },
        {
            "name": "Closed JIT Position",
            "description": "Just-in-Time position with no remaining liquidity",
            "timeCommitmentState": "JIT",
            "liquidityState": "empty",
            "notation": "liquidityTimeCommittedPosition[positionKey] == type(uint256).max && positionInfo.liquidityLevel == 0",
            "withdrawable": true
        }
    ],
    "definitions": {
        "positionKey": "keccak256(abi.encode(address(liquidityRouter), tickUpper, tickLower, salt))",
        "JIT": "type(uint256).max",
        "PositionInfo": {
            "liquidityLevel": "uint128",
            "feeGrowthInside0LastX128": "uint256",
            "feeGrowthInside1LastX128": "uint256"
        }
    }
}
```

```json
{
    "state_definitions": {
        "time_commitment_states": [
            {"state": "valid", "condition": "timeCommitment > block.timestamp"},
            {"state": "invalid", "condition": "0 < timeCommitment <= block.timestamp"},
            {"state": "JIT", "condition": "timeCommitment == type(uint256).max"},
            {"state": "empty", "condition": "timeCommitment == 0"}
        ],
        "liquidity_states": [
            {"state": "empty", "condition": "liquidityLevel == 0"},
            {"state": "non_empty", "condition": "liquidityLevel > 0"}
        ]
    },
    "position_states": [
        {
            "name": "Active Committed Position",
            "time_commitment": "valid",
            "liquidity": "non_empty",
            "notation": "timeCommitment > block.timestamp && liquidityLevel > 0",
            "withdrawable": false
        },
        {
            "name": "Expired Locked Position",
            "time_commitment": "invalid",
            "liquidity": "non_empty",
            "notation": "0 < timeCommitment <= block.timestamp && liquidityLevel > 0",
            "withdrawable": false
        },
        {
            "name": "Expired Withdrawable Position",
            "time_commitment": "invalid",
            "liquidity": "empty",
            "notation": "0 < timeCommitment <= block.timestamp && liquidityLevel == 0",
            "withdrawable": true
        },
        {
            "name": "Committed Empty Position",
            "time_commitment": "valid",
            "liquidity": "empty",
            "notation": "timeCommitment > block.timestamp && liquidityLevel == 0",
            "withdrawable": false,
            "status_note": "Inconsistent state - requires resolution"
        },
        {
            "name": "Active JIT Position",
            "time_commitment": "JIT",
            "liquidity": "non_empty",
            "notation": "timeCommitment == type(uint256).max && liquidityLevel > 0",
            "withdrawable": true
        },
        {
            "name": "Closed JIT Position",
            "time_commitment": "JIT",
            "liquidity": "empty",
            "notation": "timeCommitment == type(uint256).max && liquidityLevel == 0",
            "withdrawable": true
        },
        {
            "name": "Uncommitted Position",
            "time_commitment": "uncommitted",
            "liquidity": "empty",
            "notation": "timeCommitment == 0 && liquidityLevel == 0",
            "withdrawable": true
        }
    ],
    "add_liquidity_transitions": [
        {
            "current_state": "Active Committed Position",
            "action": "Add liquidity with valid timeCommitment",
            "response": "Update timeCommitment and increase liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Active Committed Position",
            "action": "Add liquidity with invalid timeCommitment",
            "response": "Maintain current timeCommitment, increase liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Expired Locked Position",
            "action": "Add liquidity with valid timeCommitment",
            "response": "Update timeCommitment and increase liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Expired Locked Position",
            "action": "Add liquidity with invalid timeCommitment",
            "response": "Revert with InvalidPLPAddLiquidityRequest___PLPPositionExpiredAndEnteredTimeCOmmitmentIsInvalid",
            "next_state": "Expired Locked Position",
            "error_possible": true
        },
        {
            "current_state": "Expired Withdrawable Position",
            "action": "Add liquidity with valid timeCommitment",
            "response": "Update timeCommitment and set liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Expired Withdrawable Position",
            "action": "Add liquidity with invalid timeCommitment",
            "response": "Revert with InvalidPLPAddLiquidityRequest___PLPPositionExpiredAndEnteredTimeCOmmitmentIsInvalid",
            "next_state": "Expired Withdrawable Position",
            "error_possible": true
        },
        {
            "current_state": "Committed Empty Position",
            "action": "Add liquidity with any timeCommitment",
            "response": "Update timeCommitment if valid, set liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Active JIT Position",
            "action": "Add liquidity with valid timeCommitment",
            "response": "Convert to time-based position, update commitment",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Active JIT Position",
            "action": "Add liquidity with invalid/JIT timeCommitment",
            "response": "Maintain JIT status, increase liquidity",
            "next_state": "Active JIT Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Closed JIT Position",
            "action": "Add liquidity with valid timeCommitment",
            "response": "Convert to time-based position, set liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Closed JIT Position",
            "action": "Add liquidity with invalid/JIT timeCommitment",
            "response": "Maintain JIT status, set liquidity",
            "next_state": "Active JIT Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Uncommitted Position",
            "action": "Add liquidity with valid timeCommitment",
            "response": "Set initial timeCommitment and liquidity",
            "next_state": "Active Committed Position",
            "event": "UpdtatedPLPPosition",
            "error_possible": false
        },
        {
            "current_state": "Uncommitted Position",
            "action": "Add liquidity with invalid timeCommitment",
            "response": "Revert - requires valid commitment for initialization",
            "next_state": "Uncommitted Position",
            "error_possible": true
        }
    ],
    "event_specification": {
        "name": "UpdtatedPLPPosition",
        "parameters": [
            {"name": "positionKey", "type": "bytes32", "indexed": true},
            {"name": "newTimeCommitment", "type": "uint256", "indexed": true},
            {"name": "timeDeltaWithCurrentTimeStamp", "type": "uint256", "indexed": true},
            {"name": "timeDeltaWithPreviousTimeCommitment", "type": "int256"},
            {"name": "liquidityAdded", "type": "uint256"}
        ],
        "description": "Emitted when PLP position is updated with new liquidity"
    },
    "error_specification": {
        "name": "InvalidPLPAddLiquidityRequest___PLPPositionExpiredAndEnteredTimeCOmmitmentIsInvalid",
        "description": "Reverted when expired position receives invalid time commitment"
    },
    "position_key_generation": {
        "algorithm": "keccak256(abi.encode(address(liquidityRouter), tickUpper, tickLower, salt))",
        "components": [
            "liquidityRouter address",
            "tickUpper (int24)",
            "tickLower (int24)",
            "salt (uint256)"
        ]
    }
}
```