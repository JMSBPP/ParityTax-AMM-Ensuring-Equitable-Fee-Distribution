//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    PoolId,
    PoolIdLibrary,
    PoolKey
} from "@uniswap/v4-core/src/types/PoolId.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";

import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PositionInfoLibrary, PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";

contract ParityTaxHookBase{
    using SafeCast for *;
    using Position for address;
    using PositionInfoLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;

    /// @custom:transient-storage-location erc7201:openzeppelin.transient-storage.JIT_TRANSIENT
    struct JIT_Transient_Metrics{
        //slot 1 
        uint256 addedLiquidity;
        //slot 2
        uint256 jitProfit;
        // slot 3 
        bytes32 jitPositionInfo;
        // slot 4 
        bytes32 positionKey;
        // slot 5 
        int256 withheldFees;
        

        
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32  constant JIT_Transient_MetricsLocation = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;

    function tstore_JIT_liquidity(uint256 jitLiquidity) internal {
        assembly('memory-safe'){
            tstore(JIT_Transient_MetricsLocation, jitLiquidity)
        }
    }

    function tload_JIT_addedLiquidity() internal view returns(uint256){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.addedLiquidity;
    }


    function tstore_JIT_positionKey(bytes32 jitPositionKey) internal {
        assembly('memory-safe'){
            tstore(add(JIT_Transient_MetricsLocation, 0x02), jitPositionKey)
        }
    }

    function tload_JIT_positionKey() internal view returns(bytes32){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.positionKey;
    }

    function _jitTransientMetrics() internal view returns(JIT_Transient_Metrics memory){
        bytes32 slot1;
        bytes32 slot2;
        bytes32 slot3;
        bytes32 slot4;
        assembly("memory-safe"){
            slot1 := tload(JIT_Transient_MetricsLocation)
            slot2 := tload(add(JIT_Transient_MetricsLocation, 0x01))
            slot3 := tload(add(JIT_Transient_MetricsLocation, 0x02))
            slot4 := tload(add(JIT_Transient_MetricsLocation, 0x03))
        }
        // Unpack the struct
        return JIT_Transient_Metrics({
            addedLiquidity: uint256(slot1),
            jitProfit: uint256(slot2),
            jitPositionInfo: slot2,
            positionKey: slot3,
            withheldFees : uint256(slot4).toInt256()
        });
    }



    function _jitProfit() internal view returns(uint256){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.jitProfit;
    }

    function _jitPositionInfo() internal view returns(bytes32){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.jitPositionInfo;
    }


    function _withheldFees() internal view returns(int256){
        JIT_Transient_Metrics memory jitTransientMetrics = _jitTransientMetrics();
        return jitTransientMetrics.withheldFees;
    }

    /// @custom:storage-location erc7201:openzeppelin.storage.JIT_Aggregate_Metrics
    struct JIT_Aggregate_Metrics{
        uint256 cummAddedLiquidity;
        uint256 cummProfit;
    }


    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.JIT_AGGREGATE")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 internal constant JIT_Aggregate_MetricsLocation = 0xe0cf99b8cd0560d8640e62178018c84af9084dd2b92a0b03d3120e8fa0633800;

    function _getJITAggregateMetrics() internal pure returns (JIT_Aggregate_Metrics storage $){
        assembly{
            $.slot := JIT_Aggregate_MetricsLocation
        }
    }

}