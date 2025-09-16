//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExttload} from "@uniswap/v4-core/src/interfaces/IExttload.sol";
import {PositionInfo} from "@uniswap/v4-periphery/src/libraries/PositionInfoLibrary.sol";
import "../types/Shared.sol";

interface IParityTaxExtt is IExttload{

    // ================================ PLP (Permanent Liquidity Provider) FUNCTIONS ================================

    /**
     * @notice Store PLP liquidity change in transient storage
     * @param liquidityChange The change in liquidity amount (can be positive or negative)
     */
    function tstore_plp_liquidity(int256 liquidityChange) external;

    /**
     * @notice Store PLP fees accrued in transient storage
     * @param feesAccruedOn0 The fees accrued on currency0
     * @param feesAccruedOn1 The fees accrued on currency1
     */
    function tstore_plp_feesAccrued(uint256 feesAccruedOn0, uint256 feesAccruedOn1) external;

    /**
     * @notice Store PLP token ID in transient storage
     * @param tokenId The NFT token ID representing the PLP position
     */
    function tstore_plp_tokenId(uint256 tokenId) external;

    // ================================ SWAP PRICE IMPACT FUNCTIONS ================================

    /**
     * @notice Store swap price before swap in transient storage
     * @param beforeSwapSqrtPriceX96 The sqrt price before the swap occurred
     */
    function tstore_swap_beforeSwapSqrtPriceX96(uint160 beforeSwapSqrtPriceX96) external;

    /**
     * @notice Store external swap price before swap in transient storage
     * @param beforeSwapExternalSqrtPriceX96 The external sqrt price before the swap (from oracle)
     */
    function tstore_swap_beforeSwapExternalSqrtPriceX96(uint160 beforeSwapExternalSqrtPriceX96) external;

    // ================================ JIT (Just-In-Time) LIQUIDITY FUNCTIONS ================================

    /**
     * @notice Store JIT token ID in transient storage
     * @param tokenId The NFT token ID representing the JIT position
     */
    function tstore_jit_tokenId(uint256 tokenId) external;

    /**
     * @notice Store JIT fee revenue in transient storage
     * @param feeRevenueOn0 The fee revenue accrued on currency0
     * @param feeRevenueOn1 The fee revenue accrued on currency1
     */
    function tstore_jit_feeRevenue(uint256 feeRevenueOn0, uint256 feeRevenueOn1) external;

    /**
     * @notice Store JIT position info in transient storage
     * @param positionInfo The position information including pool details
     */
    function tstore_jit_positionInfo(PositionInfo positionInfo) external;

    /**
     * @notice Store JIT liquidity amount in transient storage
     * @param liquidity The amount of liquidity in the JIT position
     */
    function tstore_jit_liquidity(uint256 liquidity) external;

    /**
     * @notice Store JIT position key in transient storage
     * @param positionKey The position key for the JIT liquidity position
     */
    function tstore_jit_positionKey(bytes32 positionKey) external;

    /**
     * @notice Store JIT position owner in transient storage
     * @param owner The address of the JIT position owner
     */
    function tstore_jit_owner(address owner) external;

    /**
     * @notice Store complete JIT liquidity position in transient storage
     * @dev Stores all JIT position data by calling individual storage functions
     * @param jitLiquidityPosition The complete JIT liquidity position data
     */
    function tstore_jit_liquidityPosition(LiquidityPosition memory jitLiquidityPosition) external;

}