// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./types/TimeCommitment.sol";
import "v4-periphery/src/base/ImmutableState.sol";

enum PositionState {
    /* 
        @dev This is an invalid position
        @notice This needs to return an error
        or be handled appropriately  
        */
    INVALID,
    /*
        @dev This a non-withdrawable position
        @notice This imposes a lock on
        beforeRemoveLiquidity for PLP positions
        */
    PLP_NON_EXPIRED_NON_EMPTY,
    /* 
        @dev This is a withdrawable position 
        */
    PLP_EXPIRED_NON_EMPTY,
    /* 
        @dev This is a PLP position without liquidity
        @notice This needs to pass to EMPTY 
        */
    PLP_EXPIRED_EMPTY,
    /* 
        @dev This is an unititialized position 
        */
    EMPTY,
    /* 
        @dev This is a JIT position that
        with liquidity 
        */
    JIT_NON_EMPTY,
    /* 
        @dev This is a JIT position 
        without liquidity
        @notice This needs to pass to EMPTY 
        */
    JIT_EMPTY
}

contract TimeLockedLiquidityManager is ImmutableState {
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
    //NOTE: This timeLocked liquidityManager needs to have an innmutable reference
    // to the poolManager to query it's state
    constructor(IPoolManager _poolManager) ImmutableState(_poolManager) {}

    //NOTE: Has a mapping of the positionKeys to their timeCommitments
    mapping(bytes32 liquidityPositionKey => TimeCommitment) liquidityTimeCommittedPosition;
    //NOTE: A a liquidityTimeCommittedPosition state is defined by
    // a timeCommitment and the liquidityLevel

    //TODO: Once a liquidity Router calls add liquidity,
    // The parityTaxHook asks for an encoded timeCommitment
    // on the hookData function param.

    // For our use case the beforeAddLiquidity can perform
    //checks to revert if the positionState is invalid or
    // not consistent with the enteredTimeCommitment. This
    // is

    function canAddLiquidity(
        bytes32 liquidityPositionKey,
        bytes calldata encodedEnteredTimeCommitment
    ) external view returns (bool) {
        //NOTE: This allows to know the nature of the request
        (
            TimeCommitment enteredTimeCommitment,
            Tag enteredTimeCommitmentTag
        ) = TimeCommitmentLibrary.decodeTagAndReturnTimeCommitment(
                encodedEnteredTimeCommitment
            );
        //NOTE Now we want to know the existing liquidityTimeCommitmentPosition
        //tag
        TimeCommitment existingTimeCommitment = liquidityTimeCommittedPosition[
            liquidityPositionKey
        ];
        Tag existingTimeCommitmentTag = existingTimeCommitment
            .tagTimeCommitment();
        //NOTE: With this we can discard the request only based on the compatibility of the
        // enteredTimeCommitment with the existingTimeCommitment tags

        // 1. If the enteredTimeCommitment is a NO_EXIST, then the LP did not
        // specify any commitment, fromnow er custom revert
        // TODO: In practice , we handle this by assigning an optimal
        // PLP timeCommitment that is given by a controller
    }
}
