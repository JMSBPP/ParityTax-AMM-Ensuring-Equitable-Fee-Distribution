// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityOperatorsRegistry.sol";
import "./routers/LPTypeLiquidityRouter.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "v4-core/types/PoolId.sol";
contract LiquidityOperatorsRegistry is ILiquidityOperatorsRegistry, Ownable {
    using LPTimeCommitmentLibrary for LPTimeCommitment;

    // NOTE: The first storage slot is the owner
    // which is the LPTypeLiquidityRouter address ...

    //TODO: We need to account for invariants that need to hoold when storing ddta on this
    // mappings ...

    //NOTE: The default value for not assigned lp's should be
    // LPType.NONE

    mapping(address liquidityProvider => LPTimeCommitment)
        private _lpTimeCommitments;
    //                                                             -tokenId-
    //                                              Pk_1 ([pl_1,pu_1], 1)
    //                                            /          .
    //                          -positionKey-    /           .
    //                         Pk_1([pl_1,pu_1])
    //                       /                  \
    //                      /       .            \
    // (lpAddress, poolId)/         .             \
    //                    \         .               Pk_m ([pl_m,pu_m], m)
    //                     \
    //                      \
    //                         Pk_N([pl_N,pu_N])
    // Each tokenId m  represents a unique liquididity position and the association with
    // the pool is done through

    // m ==> (PositionInfo :=(PoolId, tickLower, tickUpper, hasSubscriber))
    //NOTE: This function is called only by the router
    // Then to associate the position with the pool and the
    // the timeCommitment of the lp, we have:
    // lp => m => (PositionInfo, timeCommitment) . A custom positionManager
    // extension for timeCommited positions

    function setLPTimeCommitment(
        address liquidityProvider,
        LPTimeCommitment memory lpTypeTimeCommitment
    ) external onlyOwner {
        if (liquidityProvider == address(0)) {
            revert InvalidLiquidityProvider____AddressIsZero();
        }
        // NOTE: Is the address is valid
        // we now verify the commitment is valid
        LPTimeCommitment memory validLpTypeTimeCommitment = lpTypeTimeCommitment
            .validateAndSetLPTypeTimeCommitment();

        _lpTimeCommitments[liquidityProvider] = validLpTypeTimeCommitment;
    }

    function getLPTimeCommitment(
        address liquidityProvider
    ) external view returns (LPTimeCommitment memory lpTimeCommitment) {
        lpTimeCommitment = _lpTimeCommitments[liquidityProvider];
    }
}
