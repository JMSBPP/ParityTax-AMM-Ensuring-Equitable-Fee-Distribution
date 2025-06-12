// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "v4-periphery/src/utils/BaseHook.sol";
import "../types/TimeCommitment.sol";

abstract contract TimeCommitmentLiquidityManager is BaseHook {
    using Hooks for IHooks;
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
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

        TimeCommitment memory timeCommitment = hookData
            .fromBytesToTimeCommitment();

        // 2. It retrieves the liquidity that is already on the specified
        // params where the LP is looking to add liquidity

        // TODO: Considering our model where is liquidity stored,
        // can we query from the position manager ?
        // 3. It verifies whether is PLP or JIT the existing position if any:
        // It can only add more liquidity if the existing position is the same type, this is:
        // ---> If the existing position is PLP and the new liquidity request has other PLP params, it needs to adjust the position accordingly
        // ---> If the existing position is JIT and the request is JIT it only add more funds to the vaults
        // ---> If the existing position is PLP and the new liquidity request is JIT it returns incompatiblePositions Error or handles it appropiately, this is TBD
        // ---> If the existing position is JIT and the new liquidity request is PLP it returns incompatiblePositions Error or handles it appropiately, this is TBD

        // 4. Once this is done it now routes the liquidity to vaultsManager  subject to the type of LP, sending the information the vaultsManager needs to route the liquidity to the right vault manager (a.k.a JITVaults, PLPVaults).
        //From here the vaults have the responsability to manage the liquidity depending of the type of LP
    }
}
