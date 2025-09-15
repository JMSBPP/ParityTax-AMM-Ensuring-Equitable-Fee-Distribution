// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ResolverBase
 * @author ParityTax Team
 * @notice Abstract base contract for liquidity resolvers in the ParityTax system
 * @dev This contract provides the foundation for JIT and PLP liquidity resolvers,
 * offering standardized liquidity operations and access control mechanisms. It
 * integrates with Uniswap V4's position management system and the ParityTax hook
 * for efficient liquidity provision and management.
 * @dev Inherits from LiquidityOperations for Uniswap V4 integration, ImmutableState
 * for pool manager access, and AccessControl for role-based permissions. Critical
 * component in the equitable fee distribution system's liquidity management.
 * @custom:security-contact security@paritytax.com
 */

import {
    LiquidityOperations,
    Planner,
    Plan,
    PositionConfig,
    LiquidityAmounts,
    Actions
} from "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IParityTaxHook} from "../interfaces/IParityTaxHook.sol";
import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice Abstract base contract for liquidity resolvers
 * @dev Provides standardized liquidity operations and access control for JIT and PLP resolvers
 */
abstract contract ResolverBase is LiquidityOperations, ImmutableState, AccessControl{
    using Planner for Plan;

    // ================================ CUSTOM ERRORS ================================
    
    /// @notice Error thrown when hook has not been initialized
    error HookHasNotBeenSet();
    
    /// @notice Error thrown when hook has already been set
    error HookHasAlreadyBeenSet();

    // ================================ STATE VARIABLES ================================
    
    /// @notice ParityTax hook contract for liquidity management integration
    IParityTaxHook parityTaxHook;
    
    // ================================ CONSTRUCTOR ================================
    
    /**
     * @notice Initializes the ResolverBase with Uniswap V4 and ParityTax dependencies
     * @dev Sets up the resolver with pool manager, position manager, and ParityTax hook.
     * Grants admin role to the ParityTax hook for access control management.
     * @param _poolManager The Uniswap V4 pool manager contract
     * @param _lpm The Uniswap V4 position manager contract
     * @param _parityTaxHook The ParityTax hook contract for integration
     */
    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook
    ) ImmutableState(_poolManager){
        lpm = _lpm;
        parityTaxHook = _parityTaxHook;
        _grantRole(DEFAULT_ADMIN_ROLE, address(parityTaxHook));
    }

    // ================================ MODIFIERS ================================
    
    /**
     * @notice Modifier to ensure the ParityTax hook has been initialized
     * @dev Reverts if the hook address is zero, preventing operations before proper setup
     */
    modifier onlyWithHookInitialized(){
        if (address(parityTaxHook) == address(0x00)) revert HookHasNotBeenSet();
        _;
    }

    // ================================ INTERNAL FUNCTIONS ================================

    /**
     * @notice Mints a new unlocked liquidity position
     * @dev Creates a new position with the specified configuration and liquidity amount.
     * Uses Uniswap V4's planner system for atomic position creation and currency management.
     * @param config The position configuration including pool key and tick range
     * @param liquidity The amount of liquidity to mint
     * @param recipient The address to receive the position NFT
     * @param hookData Additional data to pass to the ParityTax hook
     */
    function _mintUnlocked(
        PositionConfig memory config,
        uint256 liquidity,
        address recipient,
        bytes memory hookData
    ) internal virtual {
        Plan memory planner = Planner.init();
        {
            planner.add(
                Actions.MINT_POSITION,
                abi.encode(
                    config.poolKey,
                    config.tickLower < config.tickUpper ?config.tickLower:config.tickUpper,
                    config.tickLower < config.tickUpper ?config.tickUpper:config.tickLower,
                    liquidity,
                    MAX_SLIPPAGE_INCREASE,
                    MAX_SLIPPAGE_INCREASE,
                    recipient,
                    hookData
                )
            );
            planner.add(
                Actions.CLOSE_CURRENCY,
                abi.encode(config.poolKey.currency0)
            );
            planner.add(
                Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency1)
            );
        }
        
        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }

    /**
     * @notice Burns an unlocked liquidity position completely
     * @dev Removes all liquidity from a position and closes currency accounts.
     * Uses Uniswap V4's planner system for atomic position burning and currency management.
     * @param tokenId The token ID of the position to burn
     * @param config The position configuration for currency management
     */
    function _burnUnlocked(
        uint256 tokenId,
        PositionConfig memory config
    ) internal virtual {
        Plan memory planner = Planner.init();
        planner.add(
            Actions.BURN_POSITION,
            abi.encode(
                tokenId,
                MIN_SLIPPAGE_DECREASE,
                MIN_SLIPPAGE_DECREASE,
                Constants.ZERO_BYTES
            )
        );

        planner.add(
            Actions.CLOSE_CURRENCY,
            abi.encode(config.poolKey.currency0)
        );
        planner.add(
            Actions.CLOSE_CURRENCY, 
            abi.encode(config.poolKey.currency1)
        );

        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }

    /**
     * @notice Decreases liquidity in an unlocked position
     * @dev Partially removes liquidity from a position while maintaining the position.
     * Uses Uniswap V4's planner system for atomic liquidity reduction and currency management.
     * @param tokenId The token ID of the position to modify
     * @param config The position configuration for currency management
     * @param liquidityToRemove The amount of liquidity to remove from the position
     */
    function _decreaseUnlocked(
        uint256 tokenId,
        PositionConfig memory config,
        uint256 liquidityToRemove
    ) internal virtual {
        Plan memory planner = Planner.init();
        planner.add(
            Actions.DECREASE_LIQUIDITY, 
            abi.encode(
                tokenId,
                liquidityToRemove,
                MIN_SLIPPAGE_DECREASE,
                MIN_SLIPPAGE_DECREASE,
                Constants.ZERO_BYTES
            )
        );

        planner.add(
            Actions.CLOSE_CURRENCY,
            abi.encode(config.poolKey.currency0)
        );
        
        planner.add(
            Actions.CLOSE_CURRENCY, 
            abi.encode(config.poolKey.currency1)
        );

        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }
}
