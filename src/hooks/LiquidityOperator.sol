// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/ILiquidityOperator.sol";

// TODO: Integrate with EVC which ultimately integrates with vaults
// this is each timeCommitmentPosition has a couple of vaults where each
// each has the
// Liquidity associated with each position considering the time
// and the "interest or yield generated are the swap Fees"

// Thus queriyng the Vaults is the first step to manage trading fee
// revenue generated and thus having access rigths to the vaults
// through EVC allows us to tax positions and distribute revenue
// from JIT's to PLP's

//TODO: We need to derive a unique key that associates
// the positionKey with the timeCommitment,
// What is  a good name for this key?
abstract contract LiquidityOperator is ILiquidityOperator {
    using PositionTimeCommitmentKeyLibrary for *;

    mapping(bytes32 positionKey => LiquidityTimeCommitmentData)
        private liquidityPositionsTimeCommitmentData;

    mapping(PositionTimeCommitmentKey => LiquidityPositionAccounting)
        private liquidityPositionAccountings;

    function setPositionLiquidityTimeCommitmentData(
        bytes32 positionKey,
        LiquidityTimeCommitmentData memory liquidityTimeCommitmentData
    ) external virtual {
        liquidityPositionsTimeCommitmentData[
            positionKey
        ] = liquidityTimeCommitmentData;
    }
    function getPositionLiquidityTimeCommitmentData(
        bytes32 positionKey
    )
        external
        view
        returns (LiquidityTimeCommitmentData memory liquidityTimeCommitmentData)
    {
        liquidityTimeCommitmentData = liquidityPositionsTimeCommitmentData[
            positionKey
        ];
    }

    function getLiquidityPositionAccounting(
        bytes32 positionTimeCommitmentKey
    )
        external
        view
        returns (LiquidityPositionAccounting memory liquidityPositionAccounting)
    {
        liquidityPositionAccounting = liquidityPositionAccountings[
            PositionTimeCommitmentKey.wrap(positionTimeCommitmentKey)
        ];
    }
}
