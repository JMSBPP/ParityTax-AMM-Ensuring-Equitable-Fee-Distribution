// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LiquiditySubscriptions
 * @author ParityTax Team
 * @notice Abstract contract for managing PLP liquidity subscriptions and commitments
 * @dev Handles subscription notifications, commitment tracking, and fee accrual for PLP providers
 */


import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";
import {IParityTaxHook} from "./interfaces/IParityTaxHook.sol";

import "./types/Shared.sol";

import {
    PoolId,
    PoolIdLibrary
} from "@uniswap/v4-core/src/types/PoolId.sol";


abstract contract LiquiditySubscriptions is ISubscriber {
    using PoolIdLibrary for PoolKey;
    
    /// @notice The ParityTax hook contract for integration
    IParityTaxHook parityTaxHook;

    /**
     * @notice Initializes the LiquiditySubscriptions contract
     * @dev Sets up the ParityTax hook for subscription management
     * @param _parityTaxHook The ParityTax hook contract instance
     */
    constructor(IParityTaxHook _parityTaxHook){
        parityTaxHook = _parityTaxHook;
    }

    /// @notice Mapping to track PLP liquidity commitments by pool, committer, and token ID
    mapping(PoolId poolId => mapping(address committer => mapping(uint256 tokenId => uint48 commitment))) internal _plpLiquidityCommitments;
 
    /**
     * @inheritdoc ISubscriber
     * @dev Called once a position is created to track PLP commitments
     * @dev The data has the commitment information so we have the address of the committer, the token id and the actual commitment
     */
    function notifySubscribe(uint256 tokenId, bytes memory data) external{
        Commitment memory plpCommitment = abi.decode(
            data,
            (Commitment)
        );
        (PoolKey memory poolKey,) = parityTaxHook.positionManager().getPoolAndPositionInfo(tokenId);
        _plpLiquidityCommitments[poolKey.toId()][plpCommitment.committer][tokenId] = plpCommitment.blockNumberCommitment;

    }

    /**
     * @inheritdoc ISubscriber
     * @dev Called when a position is burned to clean up commitments and notify of liquidity changes
     * @dev The owner must be the committer
     */
    function notifyBurn(uint256 tokenId, address owner, PositionInfo info, uint256 liquidity, BalanceDelta feesAccrued) external{
        _removeLiquidityCommitment(owner, tokenId);
        _notifyModifyLiquidity(tokenId, int256(liquidity),feesAccrued);
    }

    
    /**
     * @inheritdoc ISubscriber
     * @dev Called when liquidity is added or removed from a position
     */
    function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) external{
        _notifyModifyLiquidity(
            tokenId,
            liquidityChange,
            feesAccrued
        );
    }

    /**
     * @notice Internal function to handle liquidity modification notifications
     * @dev Stores liquidity changes and fee accrual in the ParityTax hook's transient storage
     * @param tokenId The token ID of the modified position
     * @param liquidityChange The change in liquidity (positive for addition, negative for removal)
     * @param feesAccrued The fees accrued on the position
     */
    function _notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) internal virtual{
        parityTaxHook.tstore_plp_liquidity(liquidityChange);

        (uint256 feesAccruedOn0, uint256 feesAccruedOn1) = (uint256(int256(feesAccrued.amount0())),uint256(int256(feesAccrued.amount1())));
        
        parityTaxHook.tstore_plp_feesAccrued(feesAccruedOn0, feesAccruedOn1);

    }
    /**
     * @inheritdoc ISubscriber
     * @dev Called when a position is unsubscribed (currently empty implementation)
     */
    function notifyUnsubscribe(uint256 tokenId) external{}

    /**
     * @notice Internal function to remove a liquidity commitment
     * @dev Clears the commitment for a specific committer and token ID
     * @param committer The address of the committer
     * @param tokenId The token ID of the position
     */
    function _removeLiquidityCommitment(
        address committer,
        uint256 tokenId
    ) internal {
        (PoolKey memory poolKey,) = parityTaxHook.positionManager().getPoolAndPositionInfo(tokenId);
        _plpLiquidityCommitments[poolKey.toId()][committer][tokenId] = NO_COMMITMENT;
    }




}