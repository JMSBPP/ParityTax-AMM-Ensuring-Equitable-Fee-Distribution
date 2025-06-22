// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v4-periphery/src/base/SafeCallback.sol";
import "../types/LPTimeCommitment.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "v4-core/types/BalanceDelta.sol";
import "../hooks/interfaces/ILiquidityOperator.sol";

import "../interfaces/ILiquidityOperatorsRegistry.sol";

error IncompatibleLPTypes__LPTypeMustBeSameAsExisting();
abstract contract LPTypeLiquidityRouter is SafeCallback {
    ILiquidityOperatorsRegistry private liquidityOperatorsRegistry;
    constructor(
        IPoolManager _poolManager,
        ILiquidityOperatorsRegistry _liquidityOperatorsRegistry
    ) SafeCallback(_poolManager) {
        setLiquidityOperatorsRegistry(_liquidityOperatorsRegistry);
    }

    //TODO: This needs to be guarded
    function setLiquidityOperatorsRegistry(
        ILiquidityOperatorsRegistry _liquidityOperatorsRegistry
    ) internal {
        liquidityOperatorsRegistry = _liquidityOperatorsRegistry;
    }

    function modifyLiquidity(
        PoolKey memory key,
        ModifyLiquidityParams memory liquidityParams,
        bytes memory hookData
    )
        public
        payable
        returns (
            // bool settleUsingBurn,
            // bool takeClaims
            BalanceDelta delta
        )
    {
        //1.hookData needs to decode to a LPTimeCommitment
        LPTimeCommitment memory lpTimeCommitment = abi.decode(
            hookData,
            (LPTimeCommitment)
        );

        // NOTE: Once the timeCommitment is set on the registry, we can
        // send
    }
}
