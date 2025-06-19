// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityTimeCommitmentHookStorage.sol";
contract LiquidityTimeCommitmentHookStorage is
    ILiquidityTimeCommitmentHookStorage
{
    using LiquidityTimeCommitmentDataLibrary for LiquidityTimeCommitmentData;
    // bytes32(uint256(keccak256("liquidityManager")) - 1)
    bytes32 constant LIQUIDITY_MANAGER_TRANSIENT_SLOT =
        0xecb0923f7552a3de97b47f457c2a44f172277c29c42426c46f92408edd89b185;
    // bytes32(uint256(keccak256("liquidityPositionKey")) - 1)
    bytes32 constant LIQUIDITY_POSITION_KEY_TRANSIENT_SLOT =
        0x8edb00dbc2d418920687cfe2696c08eb31ba83afaf8a118b5e21e9bdca6a1d18;

    mapping(bytes32 positionKey => LiquidityTimeCommitmentData)
        private liquidityPositionsTimeCommitmentData;

    mapping(bytes32 positionKey => LPType) private liquidityPositionType;

    mapping(bytes32 positionKey => mapping(LPType => ILiquidityTimeCommitmentManager))
        private liquidityManagers;

    constructor() {}
    function getLiquidityTimeCommitmentData(
        bytes32 positionKey
    ) external view returns (LiquidityTimeCommitmentData memory) {
        return liquidityPositionsTimeCommitmentData[positionKey];
    }
    function getTimeCommitment(
        bytes32 positionKey
    ) external view returns (TimeCommitment memory) {
        return
            liquidityPositionsTimeCommitmentData[positionKey]
                .getTimeCommitment();
    }
    function setLiquidityTimeCommitmentData(
        bytes32 positionKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external {
        liquidityPositionsTimeCommitmentData[
            positionKey
        ] = liquidityTimeCommitmentData;
    }

    function getLiquidityManager(
        bytes32 positionKey,
        LPType lpType
    ) external view returns (ILiquidityTimeCommitmentManager) {
        return liquidityManagers[positionKey][lpType];
    }

    function setLiquidityManager(
        bytes32 positionKey,
        LPType lpType,
        ILiquidityTimeCommitmentManager liquidityManager
    ) external {
        liquidityManagers[positionKey][lpType] = liquidityManager;
    }

    function getLiquidityPositionType(
        bytes32 positionKey
    ) external view returns (LPType) {
        return liquidityPositionType[positionKey];
    }

    function setLiquidityPositionType(
        bytes32 positionKey,
        LPType lpType
    ) external {
        liquidityPositionType[positionKey] = lpType;
    }

    function storeLiquidityManagerOnTransientStorage(
        ILiquidityTimeCommitmentManager liquidityManager
    ) external {
        //1. We need to query available slots on transient
        // storage that do not override any important data
        address liquidityManagerAddress = address(liquidityManager);
        assembly ("memory-safe") {
            tstore(LIQUIDITY_MANAGER_TRANSIENT_SLOT, liquidityManagerAddress)
        }
    }
    function storeLiquidityPositionKeyOnTransientStorage(
        bytes32 liquidityPositionKey
    ) external {
        //1. We need to query available slots on transient
        // storage that do not override any important data
        assembly ("memory-safe") {
            tstore(LIQUIDITY_POSITION_KEY_TRANSIENT_SLOT, liquidityPositionKey)
        }
    }
    function getLiquidityPositionKeyFromTransientStorage()
        external
        view
        returns (bytes32)
    {
        bytes32 liquidityPositionKey;
        assembly ("memory-safe") {
            liquidityPositionKey := tload(LIQUIDITY_POSITION_KEY_TRANSIENT_SLOT)
        }
        return liquidityPositionKey;
    }

    function getLiquidityManagerFromTransientStorage()
        external
        view
        returns (ILiquidityTimeCommitmentManager)
    {
        address liquidityManagerAddress;
        assembly ("memory-safe") {
            liquidityManagerAddress := tload(LIQUIDITY_MANAGER_TRANSIENT_SLOT)
        }
        return ILiquidityTimeCommitmentManager(liquidityManagerAddress);
    }
}
