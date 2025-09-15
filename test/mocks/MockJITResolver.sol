//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MockJITResolver
 * @author ParityTax Team
 * @notice Mock implementation of JIT resolver for testing purposes
 * @dev This contract provides a test implementation of the JIT resolver functionality,
 * enabling comprehensive testing of Just-In-Time liquidity provision and removal in the
 * ParityTax system. It implements the core JIT logic for adding and removing liquidity
 * based on swap context and market conditions.
 * @dev Inherits from JITResolverBase and implements the virtual functions for testing
 * the equitable fee distribution system's dynamic liquidity management mechanisms.
 */

import "../../src/base/JITResolverBase.sol";

import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Position} from "@uniswap/v4-core/src/libraries/Position.sol";
import {PoolKey,PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {SqrtPriceMath} from "@uniswap/v4-core/src/libraries/SqrtPriceMath.sol";
import {LiquidityMath} from "@uniswap/v4-core/src/libraries/LiquidityMath.sol";
import "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SafeCast} from "@uniswap/v4-core/src/libraries/SafeCast.sol";
import{
    Currency,
    CurrencySettler
} from "@uniswap/v4-core/test/utils/CurrencySettler.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IERC721} from "forge-std/interfaces/IERC721.sol";

import {console2} from "forge-std/Test.sol";
import {PositionManager} from "@uniswap/v4-periphery/src/PositionManager.sol";
import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PositionInfo, PositionInfoLibrary} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";

/**
 * @notice Mock implementation of JIT resolver for testing
 * @dev Provides test implementation of JIT liquidity provision and removal functionality
 */
contract MockJITResolver is JITResolverBase{
    using SafeCast for *;
    using CurrencySettler for Currency;
    using StateLibrary for IPoolManager;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;
    using PositionInfoLibrary for PositionInfo;    
    using SqrtPriceMath for uint160;
    using LiquidityAmounts for uint160;
    using TickMath for uint160;
    using Address for address;
    using Position for address;

    // ================================ STATE VARIABLES ================================
    
    /// @notice Placeholder address for JIT resolver testing
    /// @dev NOTE: This is a placeholder for testing
    address jitResolver;
    
    /// @notice Mapping of pool IDs to JIT operator position keys
    mapping(PoolId poolId => bytes32 positionKey) private jitOperators;

    // ================================ CONSTRUCTOR ================================
    
    /**
     * @notice Initializes the MockJITResolver with Uniswap V4 and ParityTax dependencies
     * @dev Sets up the mock JIT resolver for testing JIT liquidity provision and removal
     * @param _manager The Uniswap V4 pool manager contract
     * @param _lpm The Uniswap V4 position manager contract
     * @param _parityTaxHook The ParityTax hook contract for integration
     */
    constructor(
        IPoolManager _manager,
        IPositionManager _lpm,
        IParityTaxHook _parityTaxHook
    ) JITResolverBase (_manager, _lpm, _parityTaxHook) {}



    // ================================ INTERNAL FUNCTIONS ================================

    /**
     * @notice Mock implementation of JIT liquidity addition
     * @dev Creates a temporary JIT position based on swap context to fulfill swap requirements.
     * This is a test implementation that calculates optimal liquidity based on price impact
     * and creates a position spanning from current tick to expected after-swap tick.
     * @dev NOTE: This is a placeholder, further checks are needed
     * @param swapContext The swap context containing swap parameters and market data
     * @return uint256 The token ID of the created JIT position
     * @return uint256 The amount of liquidity added
     */
    function _addLiquidity(SwapContext memory swapContext) internal override returns(uint256,uint256){
        //NOTE: This is  place holder, further checks are needed
        
        uint256 amountToFullfill = swapContext.amountOut;

        // NOTE : At this point the JITHub has a debit of the amount of liquidity he will provide
        // to the swap

        uint256 jitLiquidity = uint256(
            swapContext.beforeSwapSqrtPriceX96.getLiquidityForAmount1(
                swapContext.expectedAfterSwapSqrtPriceX96,
                amountToFullfill
            )
        );
        //TODO: This is provisional, because the JITData needs to give the PoolKey not
        // the PoolId
        (, int24 currentTick,,) = poolManager.getSlot0(swapContext.poolKey.toId());
        
        PositionConfig memory jitPosition = PositionConfig({
            poolKey: swapContext.poolKey,
            tickLower: currentTick,
            tickUpper: swapContext.expectedAfterSwapTick
        });

        uint256 tokenId = lpm.nextTokenId();
        _mintUnlocked(
            jitPosition,
            jitLiquidity,
            address(this),
            Constants.ZERO_BYTES
        );
        

        // NOTE: After minting the position our position is the latest tokenId
        // minted, therefore is safe to call the nextTokenId() on the positionManager
        // to query our positionTokenId
        return (tokenId, jitLiquidity);
    }




    /**
     * @notice Mock implementation of JIT liquidity removal
     * @dev Removes the JIT position by burning the position NFT and cleaning up the position.
     * This test implementation retrieves position information and burns the unlocked position.
     * @param tokenId The token ID of the JIT position to remove
     */
    function _removeLiquidity(uint256 tokenId) internal override{
        PositionInfo jitPositionInfo = lpm.positionInfo(tokenId);

        PoolKey memory poolKey = abi.decode(
            address(lpm).functionStaticCall(
                abi.encodeWithSignature(
                    "poolKeys(bytes25)", 
                    (jitPositionInfo.poolId()))
            ),
            (PoolKey)
        );

        PositionConfig memory jitPositionConfig = PositionConfig({
            poolKey: poolKey,
            tickLower: jitPositionInfo.tickLower(),
            tickUpper: jitPositionInfo.tickUpper()
        });

        _burnUnlocked(
            tokenId,
            jitPositionConfig
        );
    }




    // ================================ TESTING FUNCTIONS ================================

    /**
     * @notice Whitelists a resolver address for testing purposes
     * @dev Internal function to set the JIT resolver address for testing scenarios
     * @param _resolver The resolver address to whitelist
     */
    function whiteListResolver(
        address _resolver
    ) internal {
        jitResolver = _resolver;
    }

    // ================================ UTILITY FUNCTIONS ================================

    /**
     * @notice Queries JIT liquidity amounts for a given pool and parameters
     * @dev Calculates the required token amounts for JIT liquidity provision based on
     * current pool state and liquidity parameters. Handles different tick ranges and
     * calculates appropriate currency amounts for liquidity provision.
     * @param poolKey The pool configuration for the liquidity calculation
     * @param jitLiquidityParams The liquidity parameters including tick range and delta
     * @return liquidity0 The amount of currency0 required for liquidity provision
     * @return liquidity1 The amount of currency1 required for liquidity provision
     * @return newLiquidity The new total liquidity after the operation
     */
    function _queryJITAmounts(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory jitLiquidityParams
    ) internal view returns(uint256 liquidity0, uint256 liquidity1, uint128 newLiquidity){
        PoolId poolId = poolKey.toId();
        (uint160 sqrtPriceX96,int24 tick,,) = poolManager.getSlot0(poolId);
        (int24 tickLower, int24 tickUpper) = (
            jitLiquidityParams.tickLower,
            jitLiquidityParams.tickUpper
        );
        uint128 liquidity = poolManager.getLiquidity(poolId);
        int256 liquidityDelta = jitLiquidityParams.liquidityDelta;
        BalanceDelta delta;
        if (tick < tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ currency0 (it's becoming more valuable) so user must provide it
                delta = toBalanceDelta(
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount0Delta(
                        TickMath.getSqrtPriceAtTick(tickUpper),
                        liquidityDelta.toInt128().toUint128(),
                        false
                    ).toInt128(),
                    int128(0x00)
                );
            } else if (tick < tickUpper) {
                delta = toBalanceDelta(
                    sqrtPriceX96.getAmount0Delta(TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta.toInt128().toUint128(), false)
                        .toInt128(),
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount1Delta(sqrtPriceX96, liquidityDelta.toInt128().toUint128(), false)
                        .toInt128()
                );

                newLiquidity = LiquidityMath.addDelta(liquidity, liquidityDelta.toInt128());
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ currency1 (it's becoming more valuable) so user must provide it
                delta = toBalanceDelta(
                    0,
                    TickMath.getSqrtPriceAtTick(tickLower).getAmount1Delta(
                        TickMath.getSqrtPriceAtTick(tickUpper), liquidityDelta.toInt128().toUint128(), false
                    ).toInt128()
                );
            }

            (liquidity0, liquidity1) = (
                delta.amount0() < 0 ? uint256(uint128(-delta.amount0())) : uint256(delta.amount0().toUint128()),
                delta.amount1() < 0 ? uint256(uint128(-delta.amount1())) : uint256(delta.amount1().toUint128())
            );

        }
}