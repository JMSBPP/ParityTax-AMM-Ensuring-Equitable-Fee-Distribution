// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolOperation.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
struct TimeCommitment {
    bool jit;
    uint256 numberOfBlocks;
}

contract LiquidityTimeCommitmentHook is BaseHook {
    IPoolManager public immutable manager;

    // mapping(PositionKey => TimeCommitment) public liquidityWithdrawalLock;
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
            beforeAddLiquidity: true, // sets liquidity lock time
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true, // unlocks and controls for liquidity withdrawal
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
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external returns (bytes4) {
        if (hookData.valid()) {
            manager.unlock(hookData);
        }
    }

    function unlockCallback(
        bytes memory rawData
    ) external onlyPoolManager returns (bytes memory res) {
        TimeCommitment memory timeCommitment = abi.decode(
            rawData,
            (TimeCommitment)
        );

        setLiquidityWithdrawalLock(timeCommitment);
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external onlyPoolManager returns (bytes4) {
        isLiquidityWithdrawable(sender, key, params);
    }

    function setLiquidityWithdrawalLock(
        TimeCommitment memory timeCommitment
    ) internal {
        if (!timeCommitment.jit) {
            // 1. get the positionKey of this liquidity order
            // Associate the positionKey with the timeCommitment
        }
    }
}
