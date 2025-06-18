// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {PoolKey} from "v4-core/types/PoolKey.sol";

/**
 * @title ILiquidityTimeCommitmentManager
 * @notice Interface for managing liquidity time commitments
 */
interface ILiquidityTimeCommitmentManager {
    /**
     * @notice Get the claimable liquidity in each currency
     * @param poolKey The pool key
     * @return claimableLiquidityOnCurrency0 The claimable liquidity on currency 0
     * @return claimableLiquidityOnCurrency1 The claimable liquidity on currency 1
     */
    function getClaimableLiquidityOnCurrencies(
        PoolKey memory poolKey
    )
        external
        view
        returns (
            uint256 claimableLiquidityOnCurrency0,
            uint256 claimableLiquidityOnCurrency1
        );
}
