// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../types/LiquidityTimeCommitmentData.sol";
import "./ILiquidityTimeCommitmentManager.sol";

/// @notice Enum that represents the type of LP (Liquidity Provider).
/// @dev This enum is used to distinguish between different types of LPs.
/// @dev PLP LPs
/// @dev JIT (Just-In-Time) LPs

enum LPType {
    /// @notice This is the default LP type, when LP does not have any position.
    NONE,
    /// @notice This is the PLP LP.
    PLP,
    /// @notice This is the JIT LP.
    JIT
}

/// @title ILiquidityTimeCommitmentHookStorage
/// @notice This interface is in charge of storing and retrieving the liquidity time commitment data for a given position key.
/// @dev This interface is used by the LiquidityTimeCommitmentHook to store and retrieve the time commitment data for a given position key.
/// @dev This interface is also used by the LiquidityTimeCommitmentRouter to retrieve the liquidity time commitment data for a given position key.
interface ILiquidityTimeCommitmentHookStorage {
    /**
     * @notice Retrieves the liquidity time commitment data for a given position key.
     * @dev This function retrieves the liquidity time commitment data for a given position key.
     * @param positionKey The unique key that identifies the liquidity position.
     * @return liquidityTimeCommitmentData The liquidity time commitment data associated with the position key.
     */
    function getLiquidityTimeCommitmentData(
        bytes32 positionKey
    ) external view returns (LiquidityTimeCommitmentData memory);

    /**
     * @notice Sets the liquidity time commitment data for a given position key.
     * @dev This function sets the liquidity time commitment data for a given position key.
     * @param positionKey The unique key that identifies the liquidity position.
     * @param liquidityTimeCommitmentData The liquidity time commitment data to be set.
     */
    function setLiquidityTimeCommitmentData(
        bytes32 positionKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external;

    /**
     * @notice Retrieves the time commitment for a given position key.
     * @dev This function retrieves the time commitment for a given position key.
     * @param positionKey The unique key that identifies the liquidity position.
     * @return timeCommitment The time commitment associated with the position key.
     */
    function getTimeCommitment(
        bytes32 positionKey
    ) external view returns (TimeCommitment memory);

    /**
     * @notice Retrieves the liquidity manager for a given position key and LP type.
     * @param positionKey The unique key that identifies the liquidity position.
     * @param lpType The type of liquidity position.
     * @return liquidityManager The liquidity manager associated with the position key and LP type.
     */
    function getLiquidityManager(
        bytes32 positionKey,
        LPType lpType
    ) external view returns (ILiquidityTimeCommitmentManager liquidityManager);

    /**
     * @notice Sets the liquidity manager for a given position key and LP type.
     * @param positionKey The unique key that identifies the liquidity position.
     * @param lpType The type of liquidity position.
     * @param liquidityManager The liquidity manager to be associated with the position key and LP type.
     */
    function setLiquidityManager(
        bytes32 positionKey,
        LPType lpType,
        ILiquidityTimeCommitmentManager liquidityManager
    ) external;

    /**
     * @notice Retrieves the liquidity position type for a given position key.
     * @param positionKey The unique key that identifies the liquidity position.
     * @return lpType The type of liquidity position.
     */
    function getLiquidityPositionType(
        bytes32 positionKey
    ) external view returns (LPType);

    /**
     * @notice Sets the liquidity position type for a given position key.
     * @param positionKey The unique key that identifies the liquidity position.
     * @param lpType The type of liquidity position to be set.
     */
    function setLiquidityPositionType(
        bytes32 positionKey,
        LPType lpType
    ) external;
}
