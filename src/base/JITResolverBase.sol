//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {Exttload} from "@uniswap/v4-core/src/Exttload.sol";
import {IJITResolver} from "../interfaces/IJITResolver.sol";
import "../types/Shared.sol";


abstract contract JITResolverBase is IJITResolver, Exttload{

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant internal JIT_LIQUIDITY_LOCATION = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;
    bytes32 constant internal JIT_POSITION_KEY_LOCATION = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def01;

    function jitLiquidityLocation() external view returns(bytes32){
        return JIT_LIQUIDITY_LOCATION;
    }

    function jitPositionKeyLocation() external view returns(bytes32){
        return JIT_POSITION_KEY_LOCATION;
    }

    function _tstore_JIT_liquidity(uint256 jitLiquidity) internal {
        assembly('memory-safe'){
            tstore(JIT_Transient_MetricsLocation, jitLiquidity)
        }
    }


    function _tstore_JIT_positionKey(bytes32 jitPositionKey) internal {
        assembly('memory-safe'){
            tstore(add(JIT_Transient_MetricsLocation, 0x01), jitPositionKey)
        }
    }






}







