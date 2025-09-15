//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FeeRevenueInfo
 * @author ParityTax Team
 * @notice Packed data structure for efficient fee revenue tracking in the ParityTax system
 * @dev FeeRevenueInfo is a gas-optimized packed version of a solidity structure that stores
 * fee revenue information for both JIT and PLP liquidity providers. Using the packed version
 * saves gas and memory by not storing structure fields in separate memory slots.
 * @dev This type is critical for the equitable fee distribution system, enabling efficient
 * tracking of fee revenue across different liquidity provider types and commitment periods.
 */

import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";

/**
 * @notice Packed fee revenue information structure
 * @dev Layout: 80 bits feeRevenue1 | 80 bits feeRevenue0 | 48 bits commitment | 48 bits startBlock
 * @dev Fields from least significant bit:
 * - uint48 startBlock: The start block of the fee revenue period
 * - uint48 commitment: The commitment amount for the fee revenue period  
 * - uint80 feeRevenue0: The fee revenue for token0
 * - uint80 feeRevenue1: The fee revenue for token1
 */
type FeeRevenueInfo is uint256;

using FeeRevenueInfoLibrary for FeeRevenueInfo global;

/**
 * @title FeeRevenueInfoLibrary
 * @author ParityTax Team
 * @notice Library for manipulating packed FeeRevenueInfo data structures
 * @dev Provides gas-efficient functions for creating, reading, and converting FeeRevenueInfo
 * structures. Uses assembly for optimal bit manipulation to extract and pack data fields.
 * @dev Critical for the ParityTax system's fee tracking and taxation calculations.
 */
library FeeRevenueInfoLibrary {
    /// @notice Empty FeeRevenueInfo constant for initialization
    FeeRevenueInfo internal constant EMPTY_FEE_REVENUE_INFO = FeeRevenueInfo.wrap(0);

    // ================================ BIT MANIPULATION CONSTANTS ================================
    
    /// @notice 48-bit mask for extracting startBlock and commitment fields
    uint256 internal constant MASK_48_BITS = 0xFFFFFFFFFFFF;
    
    /// @notice 80-bit mask for extracting fee revenue fields
    uint256 internal constant MASK_80_BITS = 0xFFFFFFFFFFFFFFFFFFFF;
    
    /// @notice 128-bit mask for extracting balance delta fields
    uint256 internal constant MASK_128_BITS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    // ================================ FIELD OFFSET CONSTANTS ================================
    
    /// @notice Bit offset for startBlock field (0 bits from LSB)
    uint8 internal constant START_BLOCK_OFFSET = 0;
    
    /// @notice Bit offset for commitment field (48 bits from LSB)
    uint8 internal constant COMMITMENT_OFFSET = 48;
    
    /// @notice Bit offset for feeRevenue0 field (96 bits from LSB)
    uint8 internal constant FEE_REVENUE_0_OFFSET = 96;
    
    /// @notice Bit offset for feeRevenue1 field (176 bits from LSB)
    uint8 internal constant FEE_REVENUE_1_OFFSET = 176;

    // ================================ GETTER FUNCTIONS ================================

    /**
     * @notice Extracts the start block from a FeeRevenueInfo
     * @dev Uses assembly for gas-efficient bit manipulation
     * @param info The packed FeeRevenueInfo to extract from
     * @return _startBlock The start block of the fee revenue period
     */
    function startBlock(FeeRevenueInfo info) internal pure returns (uint48 _startBlock) {
        assembly ("memory-safe") {
            _startBlock := and(MASK_48_BITS, info)
        }
    }

    /**
     * @notice Extracts the commitment from a FeeRevenueInfo
     * @dev Uses assembly for gas-efficient bit manipulation
     * @param info The packed FeeRevenueInfo to extract from
     * @return _commitment The commitment amount for the fee revenue period
     */
    function commitment(FeeRevenueInfo info) internal pure returns (uint48 _commitment) {
        assembly ("memory-safe") {
            _commitment := and(MASK_48_BITS, shr(COMMITMENT_OFFSET, info))
        }
    }

    /**
     * @notice Extracts the fee revenue for token0 from a FeeRevenueInfo
     * @dev Uses assembly for gas-efficient bit manipulation
     * @param info The packed FeeRevenueInfo to extract from
     * @return _feeRevenue0 The fee revenue for token0
     */
    function feeRevenue0(FeeRevenueInfo info) internal pure returns (uint80 _feeRevenue0) {
        assembly ("memory-safe") {
            _feeRevenue0 := and(MASK_80_BITS, shr(FEE_REVENUE_0_OFFSET, info))
        }
    }

    /**
     * @notice Extracts the fee revenue for token1 from a FeeRevenueInfo
     * @dev Uses assembly for gas-efficient bit manipulation
     * @param info The packed FeeRevenueInfo to extract from
     * @return _feeRevenue1 The fee revenue for token1
     */
    function feeRevenue1(FeeRevenueInfo info) internal pure returns (uint80 _feeRevenue1) {
        assembly ("memory-safe") {
            _feeRevenue1 := and(MASK_80_BITS, shr(FEE_REVENUE_1_OFFSET, info))
        }
    }

    // ================================ CONSTRUCTOR FUNCTION ================================

    /**
     * @notice Creates a new FeeRevenueInfo struct with the provided parameters
     * @dev Uses assembly for gas-efficient bit packing of all fields into a single uint256
     * @param _startBlock The start block of the fee revenue period
     * @param _commitment The commitment amount for the fee revenue period
     * @param _feeRevenue0 The fee revenue for token0
     * @param _feeRevenue1 The fee revenue for token1
     * @return info The packed FeeRevenueInfo struct
     */
    function init(
        uint48 _startBlock,
        uint48 _commitment,
        uint80 _feeRevenue0,
        uint80 _feeRevenue1
    ) internal pure returns (FeeRevenueInfo info) {
        assembly {
            info :=
                or(
                    or(
                        or(
                            and(MASK_48_BITS, _startBlock),
                            shl(COMMITMENT_OFFSET, and(MASK_48_BITS, _commitment))
                        ),
                        shl(FEE_REVENUE_0_OFFSET, and(MASK_80_BITS, _feeRevenue0))
                    ),
                    shl(FEE_REVENUE_1_OFFSET, and(MASK_80_BITS, _feeRevenue1))
                )
        }
    }

    // ================================ CONVERSION FUNCTIONS ================================

    /**
     * @notice Converts FeeRevenueInfo to BalanceDelta for Uniswap V4 compatibility
     * @dev Extracts fee revenue amounts and packs them into a BalanceDelta format
     * @param feeRevenueInfo The FeeRevenueInfo to convert
     * @return BalanceDelta containing the fee revenue amounts
     */
    function toBalanceDelta(
        FeeRevenueInfo feeRevenueInfo
    ) internal pure returns (BalanceDelta) {
        return BalanceDelta.wrap(
            int128(int80(feeRevenueInfo.feeRevenue0())) | 
            (int128(int80(feeRevenueInfo.feeRevenue1())) << 64)
        );
    }

    /**
     * @notice Converts BalanceDelta to FeeRevenueInfo with additional metadata
     * @dev Extracts fee amounts from BalanceDelta and combines with block and commitment data
     * @param feeDelta The BalanceDelta containing fee amounts
     * @param _startBlock The start block of the fee revenue period
     * @param _commitment The commitment amount for the fee revenue period
     * @return FeeRevenueInfo The packed fee revenue information
     */
    function toFeeRevenueInfo(
        BalanceDelta feeDelta,
        uint48 _startBlock,
        uint48 _commitment
    ) internal pure returns (FeeRevenueInfo) {
        int256 delta = BalanceDelta.unwrap(feeDelta);
        uint80 _feeRevenue0 = uint80(int80(int128(delta)));
        uint80 _feeRevenue1 = uint80(int80(int128(delta >> 64)));
        
        return init(_startBlock, _commitment, _feeRevenue0, _feeRevenue1);
    }
}