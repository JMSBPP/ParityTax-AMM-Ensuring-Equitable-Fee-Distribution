// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MockPLPResolver
 * @author ParityTax Team
 * @notice Mock implementation of Passive Liquidity Provider (PLP) resolver for testing purposes
 * @dev This contract provides a test implementation of the PLP resolver functionality,
 * enabling comprehensive testing of Passive Liquidity Provider commitments and removals in the
 * ParityTax system. It implements the core PLP logic for managing long-term liquidity
 * commitments with specific block number commitments and reward distribution.
 * @dev Inherits from IPLPResolver for interface compliance and PLPResolverBase for standardized
 * PLP operations. Critical component for testing the equitable fee distribution system's
 * passive liquidity management and reward distribution mechanisms.
 */

import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";
import "../../src/base/PLPResolverBase.sol";
import {PositionConfig} from "@uniswap/v4-periphery/test/shared/PositionConfig.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice Mock implementation of PLP resolver for testing
 * @dev Provides test implementation of PLP liquidity commitment and management functionality
 */
contract MockPLPResolver is IPLPResolver, PLPResolverBase{
    using SafeCast for *;
    using Address for address;
    using PositionInfoLibrary for PositionInfo;
    
    // ================================ CONSTRUCTOR ================================
    
    /**
     * @notice Initializes the MockPLPResolver with Uniswap V4 and ParityTax dependencies
     * @dev Sets up the mock PLP resolver for testing PLP liquidity commitments and removals
     * @param _poolManager The Uniswap V4 pool manager contract
     * @param _lpm The Uniswap V4 position manager contract
     * @param _parityTaxHook The ParityTax hook contract for integration
     */
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook 
    ) PLPResolverBase(_poolManager, _lpm, _parityTaxHook){}

    // ================================ INTERNAL FUNCTIONS ================================

    // NOTE: The _commitLiquidity function is commented out as it's not implemented in this mock
    // function _commitLiquidity(
    //     PoolKey memory poolKey,
    //     ModifyLiquidityParams memory liquidityParams,
    //     uint48 blockNumber
    // ) internal override {
    // }
    
    /**
     * @notice Mock implementation of PLP liquidity removal
     * @dev Removes liquidity from a PLP position with support for both partial and complete removal.
     * PLPs can perform liquidity decrease operations that do not empty their positions as long as
     * their position block commitment has already expired.
     * @dev TODO: PLP's do not necessarily have to burn their position but they can 
     * do liquidity DECREASE operations that do not empty their positions as long as
     * their position block commitment has already expired
     * @param poolId The pool identifier for the position
     * @param tokenId The token ID of the position to modify
     * @param liquidityDelta The amount of liquidity to remove (negative value)
     */
    function _removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) internal override {
        
        PositionInfo plpPositionInfo = lpm.positionInfo(tokenId);
        
        uint256 plpPositionLiquidity = lpm.getPositionLiquidity(tokenId);
        
        PoolKey memory poolKey = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "poolKeys(bytes25)", 
                    (plpPositionInfo.poolId()))
            ),
            (PoolKey)
        );

        PositionConfig memory plpPositionConfig = PositionConfig({
            poolKey: poolKey,
            tickLower: plpPositionInfo.tickLower(),
            tickUpper: plpPositionInfo.tickUpper()
        });


        if (uint256(liquidityDelta) == plpPositionLiquidity){
            _burnUnlocked(
                tokenId,
                plpPositionConfig
            );
        } else if (uint256(liquidityDelta) < plpPositionLiquidity){
            _decreaseUnlocked(
                tokenId,
                plpPositionConfig,
                uint256(liquidityDelta)
            );
        }
        
    }



}