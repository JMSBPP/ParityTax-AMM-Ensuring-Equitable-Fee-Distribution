// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {ISubscriber} from "@uniswap/v4-periphery/src/interfaces/ISubscriber.sol";
import {IParityTaxHook} from "./interfaces/IParityTaxHook.sol";

import "./types/Shared.sol";

import {
    PoolId,
    PoolIdLibrary
} from "@uniswap/v4-core/src/types/PoolId.sol";


abstract contract LiquiditySubscriptions is ISubscriber {
    using PoolIdLibrary for PoolKey;
    IParityTaxHook parityTaxHook;

    constructor(IParityTaxHook _parityTaxHook){
        parityTaxHook = _parityTaxHook;
    }


    mapping(PoolId poolId => mapping(address committer => mapping(uint256 tokenId => uint48 commitment))) internal _plpLiquidityCommitments;
 
    //NOTE: This function is called once a position is created 
    function notifySubscribe(uint256 tokenId, bytes memory data) external{
        //NOTE The data has the commitment information 
        // so we have the address of the commiter, the token id and 
        // the actual commitment
        Commitment memory plpCommitment = abi.decode(
            data,
            (Commitment)
        );
        (PoolKey memory poolKey,) = parityTaxHook.positionManager().getPoolAndPositionInfo(tokenId);
        _plpLiquidityCommitments[poolKey.toId()][plpCommitment.committer][tokenId] = plpCommitment.blockNumberCommitment;

    }

    function notifyBurn(uint256 tokenId, address owner, PositionInfo info, uint256 liquidity, BalanceDelta feesAccrued) external{
        //NOTE: The owner must be the committer. Then.
        _removeLiquidityCommitment(owner, tokenId);
        _notifyModifyLiquidity(tokenId, int256(liquidity),feesAccrued);
    }

    
    function notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) external{
        _notifyModifyLiquidity(
            tokenId,
            liquidityChange,
            feesAccrued
        );
    }

    function _notifyModifyLiquidity(uint256 tokenId, int256 liquidityChange, BalanceDelta feesAccrued) internal virtual{
        parityTaxHook.tstore_plp_liquidity(liquidityChange);

        (uint256 feesAccruedOn0, uint256 feesAccruedOn1) = (uint256(int256(feesAccrued.amount0())),uint256(int256(feesAccrued.amount1())));
        
        parityTaxHook.tstore_plp_feesAccrued(feesAccruedOn0, feesAccruedOn1);

    }
    function notifyUnsubscribe(uint256 tokenId) external{}

    function _removeLiquidityCommitment(
        address committer,
        uint256 tokenId
    ) internal {
        (PoolKey memory poolKey,) = parityTaxHook.positionManager().getPoolAndPositionInfo(tokenId);
        _plpLiquidityCommitments[poolKey.toId()][committer][tokenId] = NO_COMMITMENT;
    }




}