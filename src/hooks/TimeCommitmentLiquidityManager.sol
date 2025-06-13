// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/utils/BaseHook.sol";
import "../types/TimeCommitment.sol";
import {Position} from "v4-core/libraries/Position.sol";

error IncompatiblePositionTimeCommitments();
abstract contract TimeCommitmentLiquidityManager is BaseHook {
    using Hooks for IHooks;
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
    using Position for *; // NOTE: This is mostly use to query positionKeys to them
    // associate position keys with time commitments

    mapping(bytes32 positionKey => TimeCommitment)
        private liquidityTimeCommitments;

    constructor(IPoolManager _manager) BaseHook(_manager) {}

    function getHookPermissions()
        public
        pure
        override(BaseHook)
        returns (Hooks.Permissions memory permissions)
    {
        permissions = Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
    //NOTE: At this point of the transaction the HookData has been already verified
    // to be correct or not, if not correct the transaction would have ended on the router
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override(BaseHook) onlyPoolManager returns (bytes4) {
        // 1 It decodes the timeCommitment data passed
        // on the hookData from the poolManager

        TimeCommitment memory enteredTimeCommitment = hookData
            .fromBytesToTimeCommitment();

        // 2. It retrieves the liquidity that is already on the specified
        // params where the LP is looking to add liquidity

        // TODO: Considering our model where is liquidity stored,
        // can we query from the position manager ?
        //
        // For liquidity to be trackable by the poolManager
        // it must be stored in the positionManager and managed by
        // ERC6909 claims,

        // Assuming this is the case, we need to query the position
        // liquidity from the poolManager
        // If sender is the LP asscociated with the position,
        //  ->  Then it follows:

        bytes32 liquidityPositionKey = sender.calculatePositionKey(
            params.tickLower,
            params.tickUpper,
            params.salt
        );

        // We can now get the TimeCommitment associated with the
        // liquidityPositionKey
        // NOTE: The time commitment is assumed to be valid because
        // it was checked before being entered
        TimeCommitment memory existingTimeCommitment = liquidityTimeCommitments[
            liquidityPositionKey
        ].validateCommitment();

        // 3. It verifies whether is PLP or JIT the existing position if any:
        // It can only add more liquidity if the existing position is the same type,
        //
        //--> This is:
        // ================================================================================================
        // ===============================PLP -> JIT  v JIT -> PLP ===============================================
        if (
            (!(existingTimeCommitment.isJIT) && enteredTimeCommitment.isJIT) ||
            (existingTimeCommitment.isJIT && !(enteredTimeCommitment.isJIT))
        ) {
            revert IncompatiblePositionTimeCommitments();
        }
        // ---> If the existing position is PLP and the new liquidity request has other PLP params,
        //  it needs to adjust the position accordingly
        //==============================PLP -> PLP ===============================================
        if (!(existingTimeCommitment.isJIT) && !(enteredTimeCommitment.isJIT)) {
            // TODO: It needs to adjust the position accordingly
            // NOTE: Since the approach to be taken is liquidity to be stored
            // in the positionManager and managed by ERC-6909 claims
            // 1. The JITVaultManager takes the liquidity from the positionManager
            // 2. We verify that this indeed happened .
            // we need a "ClaimsManager" instead of "VaultManager",
            // And the claim tokens are the ones stored on "Vaults", in this case
            // PLP vaults, to earn passive income...
        }

        // ---> If the existing position is JIT and the request is JIT it only add more funds to the vaults
        // ==============================JIT -> JIT ===============================================
        if (existingTimeCommitment.isJIT && enteredTimeCommitment.isJIT) {
            // TODO: It only add more funds to the vaults
            // NOTE: In this case the "ClaimsManager" does not route the funds
            // to "PLPVaults" but to "JITClaim" manager that has a reference ta JITHook
            // This hook selects the orders where to apply JIT liquidity
        }
        // We could only query the liquidity but:
        // QUESTION:
        // Is it possible to have zero liquidity and positive fees?

        // For sanity check we only consider that a position does no exists
        // if all the values are zero:

        // 4. Once this is done it now routes the liquidity to vaultsManager  subject to the type of LP, sending the information the vaultsManager needs to route the liquidity to the right vault manager (a.k.a JITVaults, PLPVaults).
        //From here the vaults have the responsability to manage the liquidity depending of the type of LP
        return IHooks.beforeAddLiquidity.selector;
    }
}
