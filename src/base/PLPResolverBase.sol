// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PLPResolverBase
 * @author ParityTax Team
 * @notice Abstract base contract for Passive Liquidity Provider (PLP) resolvers
 * @dev This contract provides the foundation for PLP liquidity management in the ParityTax system,
 * handling long-term liquidity commitments with specific block number commitments. PLP resolvers
 * enable enhanced reward distribution for liquidity providers who commit to longer-term positions,
 * supporting the equitable fee distribution system's passive liquidity management.
 * @dev Inherits from IPLPResolver for interface compliance and ResolverBase for standardized
 * liquidity operations. Critical component in the reward distribution mechanism for committed
 * liquidity providers.
 */

import {IPLPResolver, PoolId} from "../../src/interfaces/IPLPResolver.sol";

import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";

import "../types/Shared.sol";
import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import "./ResolverBase.sol";

/**
 * @notice Abstract base contract for PLP resolvers
 * @dev Provides standardized PLP liquidity commitment and management functionality
 */
abstract contract PLPResolverBase is IPLPResolver,ResolverBase{
    // ================================ DATA STRUCTURES ================================
    
    /**
     * @notice Structure for yield generation configuration per pool
     * @dev Contains ERC4626 vault addresses for yield generation on each currency
     * @param yieldOnCurrency0 ERC4626 vault for yield generation on currency0
     * @param yieldOnCurrency1 ERC4626 vault for yield generation on currency1
     */
    struct YieldGenerator{
        IERC4626 yieldOnCurrency0;
        IERC4626 yieldOnCurrency1;
    }
    
    // ================================ STATE VARIABLES ================================
    
    /// @notice Mapping of pool IDs to their yield generation configuration
    mapping(PoolId => YieldGenerator) pairYieldGenerator;

    // ================================ CONSTRUCTOR ================================
    
    /**
     * @notice Initializes the PLPResolverBase with Uniswap V4 and ParityTax dependencies
     * @dev Sets up the PLP resolver with pool manager, position manager, and ParityTax hook.
     * Inherits access control and liquidity operations from ResolverBase.
     * @param _poolManager The Uniswap V4 pool manager contract
     * @param _lpm The Uniswap V4 position manager contract
     * @param _parityTaxHook The ParityTax hook contract for integration
     */
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook
    ) ResolverBase(_poolManager, _lpm,_parityTaxHook){
    }

    // ================================ EXTERNAL FUNCTIONS ================================

    /**
     * @inheritdoc IPLPResolver
     * @dev Commits liquidity for a Passive Liquidity Provider with block number commitment
     */
    function commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        address committer,
        uint48 blockNumber
    ) external onlyWithHookInitialized() onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256){
        //NOTE Associates the committer with the owner of the position
        uint256 tokenId = lpm.nextTokenId();

        PositionConfig memory plpPosition = PositionConfig({
            poolKey: poolKey,
            tickLower: liquidityParams.tickLower,
            tickUpper: liquidityParams.tickUpper
        });

        _mintUnlocked(
            plpPosition,
            uint256(liquidityParams.liquidityDelta),
            committer,
            Constants.ZERO_BYTES
        );
        _commitLiquidity(poolKey, liquidityParams, committer, blockNumber);
        return tokenId;
    }

    /**
     * @inheritdoc IPLPResolver
     * @dev Removes liquidity from a PLP position with commitment validation
     */
    function removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) external onlyWithHookInitialized() onlyRole(DEFAULT_ADMIN_ROLE){}
    
    // ================================ INTERNAL FUNCTIONS ================================

    /**
     * @notice Internal function to commit liquidity with specific block number
     * @dev Virtual function to be implemented by concrete PLP resolver implementations.
     * Handles the actual commitment logic including validation and storage.
     * @param poolKey The pool configuration for the liquidity position
     * @param liquidityParams The liquidity parameters including tick range and amount
     * @param committer The address committing the liquidity
     * @param blockNumber The block number until which liquidity must be committed
     * @return uint256 The token ID of the created position
     */
    function _commitLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        address committer,
        uint48 blockNumber
    ) internal virtual returns(uint256){}

    /**
     * @notice Internal function to remove liquidity from a PLP position
     * @dev Virtual function to be implemented by concrete PLP resolver implementations.
     * Handles the actual removal logic including commitment validation and penalties.
     * @param poolId The pool identifier for the position
     * @param tokenId The token ID of the position to modify
     * @param liquidityDelta The amount of liquidity to remove (negative value)
     */
    function _removeLiquidity(
        PoolId poolId,
        uint256 tokenId,
        int256 liquidityDelta
    ) internal virtual{}

    

    

}


