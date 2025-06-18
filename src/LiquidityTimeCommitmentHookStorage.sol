// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityTimeCommitmentHookStorage.sol";

contract LiquidityTimeCommitmentHookStorage is
    ILiquidityTimeCommitmentHookStorage
{
    using LiquidityTimeCommitmentDataLibrary for LiquidityTimeCommitmentData;
    mapping(bytes32 positionKey => LiquidityTimeCommitmentData)
        private liquidityPositionsTimeCommitmentData;

    mapping(bytes32 positionKey => LPType) private liquidityPositionType;

    mapping(bytes32 positionKey => mapping(LPType => ILiquidityManager))
        private liquidityManagers;

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
    ) external view returns (ILiquidityManager) {
        return liquidityManagers[positionKey][lpType];
    }

    function setLiquidityManager(
        bytes32 positionKey,
        LPType lpType,
        ILiquidityManager liquidityManager
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
}
