//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";

/**
 * @dev FeeRevenueInfo is a packed version of solidity structure.
 * Using the packaged version saves gas and memory by not storing the structure fields in memory slots.
 *
 * Layout:
 * 80 bits feeRevenue1 | 80 bits feeRevenue0 | 48 bits commitment | 48 bits startBlock
 *
 * Fields in the direction from the least significant bit:
 *
 * The start block of the fee revenue period
 * uint48 startBlock;
 *
 * The commitment amount for the fee revenue period
 * uint48 commitment;
 *
 * The fee revenue for token0
 * uint80 feeRevenue0;
 *
 * The fee revenue for token1
 * uint80 feeRevenue1;
 *
 */
// uint48 startBlock, uint48 commitment, uint80 feeRevenue0, uint80 feeRevenue1
type FeeRevenueInfo is uint256;

using FeeRevenueInfoLibrary for FeeRevenueInfo global;

library FeeRevenueInfoLibrary {
    FeeRevenueInfo internal constant EMPTY_FEE_REVENUE_INFO = FeeRevenueInfo.wrap(0);

    uint256 internal constant MASK_48_BITS = 0xFFFFFFFFFFFF;
    uint256 internal constant MASK_80_BITS = 0xFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant MASK_128_BITS = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    uint8 internal constant START_BLOCK_OFFSET = 0;
    uint8 internal constant COMMITMENT_OFFSET = 48;
    uint8 internal constant FEE_REVENUE_0_OFFSET = 96;
    uint8 internal constant FEE_REVENUE_1_OFFSET = 176;

    function startBlock(FeeRevenueInfo info) internal pure returns (uint48 _startBlock) {
        assembly ("memory-safe") {
            _startBlock := and(MASK_48_BITS, info)
        }
    }

    function commitment(FeeRevenueInfo info) internal pure returns (uint48 _commitment) {
        assembly ("memory-safe") {
            _commitment := and(MASK_48_BITS, shr(COMMITMENT_OFFSET, info))
        }
    }

    function feeRevenue0(FeeRevenueInfo info) internal pure returns (uint80 _feeRevenue0) {
        assembly ("memory-safe") {
            _feeRevenue0 := and(MASK_80_BITS, shr(FEE_REVENUE_0_OFFSET, info))
        }
    }

    function feeRevenue1(FeeRevenueInfo info) internal pure returns (uint80 _feeRevenue1) {
        assembly ("memory-safe") {
            _feeRevenue1 := and(MASK_80_BITS, shr(FEE_REVENUE_1_OFFSET, info))
        }
    }

    /// @notice Creates the default FeeRevenueInfo struct
    /// @dev Called when initializing fee revenue tracking
    /// @param _startBlock the start block of the fee revenue period
    /// @param _commitment the commitment amount for the fee revenue period
    /// @param _feeRevenue0 the fee revenue for token0
    /// @param _feeRevenue1 the fee revenue for token1
    /// @return info packed fee revenue info
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

    function toBalanceDelta(
        FeeRevenueInfo feeRevenueInfo
    ) internal pure returns (BalanceDelta) {
        return BalanceDelta.wrap(
            int128(int80(feeRevenueInfo.feeRevenue0())) | 
            (int128(int80(feeRevenueInfo.feeRevenue1())) << 64)
        );
    }

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