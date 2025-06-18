// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../types/LiquidityTimeCommitmentData.sol";
import "./ILiquidityManager.sol";

enum LPType {
    NONE, //NOTE: This is the default LP type, when LP does not have any position
    PLP, //NOTE: This is the PLP LP
    JIT //NOTE: This is the JIT LP
}
interface ILiquidityTimeCommitmentHookStorage {
    function getLiquidityTimeCommitmentData(
        bytes32 positionKey
    ) external view returns (LiquidityTimeCommitmentData memory);

    function setLiquidityTimeCommitmentData(
        bytes32 positionKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external;

    function getTimeCommitment(
        bytes32 positionKey
    ) external view returns (TimeCommitment memory);

    function getLiquidityManager(
        bytes32 positionKey,
        LPType lpType
    ) external view returns (ILiquidityManager);

    function setLiquidityManager(
        bytes32 positionKey,
        LPType lpType,
        ILiquidityManager liquidityManager
    ) external;

    function getLiquidityPositionType(
        bytes32 positionKey
    ) external view returns (LPType);

    function setLiquidityPositionType(
        bytes32 positionKey,
        LPType lpType
    ) external;
}
