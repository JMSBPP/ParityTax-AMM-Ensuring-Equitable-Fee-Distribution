//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/IJITResolver.sol";
import "./ResolverBase.sol";

abstract contract JITResolverBase is IJITResolver, ResolverBase{

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.transient-storage.JIT_TRANSIENT")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant JIT_Transient_MetricsLocation = 0xea3262c41a64b3c1fbce2786641b7f7461a1dc7c180ec16bb38fbe7e610def00;

    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm
    ) ResolverBase(_poolManager, _lpm){}


}







