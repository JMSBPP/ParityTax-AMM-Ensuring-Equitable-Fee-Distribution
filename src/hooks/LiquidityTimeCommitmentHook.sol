// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolId.sol";
import "v4-core/types/PoolOperation.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Position} from "v4-core/libraries/Position.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";

struct TimeCommitment {
    address liquidityProvider;
    bool longTerm;
    uint256 numberOfBlocks;
    uint256 startingBlockNumber;
}
// lp -> liquidityRouter -> poolManager
//msg.sender == PoolManager
// sender == liquidityRouter
// How do I find the underlying
//liquidity Provider address
contract LiquidityTimeCommitmentHook is BaseHook {
    using Position for address;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for *;
    IPoolManager public immutable manager;

    event NewTimeCommitment(
        address indexed sender,
        PoolId indexed poolId,
        bytes32 indexed positionKey,
        TimeCommitment timeCommitment
    );
    error LockedLiquidity();
    // The position Key has an associated owner
    // I am saying the liquidity Prrovider with positionKey for this pool has a time commitment of ...
    mapping(bytes32 positionKey => mapping(PoolId poolId => TimeCommitment timeCommitment))
        private timeCommitments;

    constructor(IPoolManager poolManager) BaseHook(poolManager) {}

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
    ) external override(BaseHook) onlyPoolManager returns (bytes4) {
        // With valid we mean that it decodes to a TimeCommitmentParams
        // Pool.State storage pool = _getPool(id);
        TimeCommitment memory timeCommitment = abi.decode(
            hookData,
            (TimeCommitment)
        );

        (bytes32 lpPositionKey, PoolId poolId) = getTimeCommitmentKeys(
            timeCommitment.liquidityProvider,
            key,
            params
        );
        // This poolKeyLPPositionKey has an associated timeCommitment
        // bytes32 PoolStateSlot = key.toId()._getPoolStateSlot();
        timeCommitments[lpPositionKey][poolId] = timeCommitment;
        liquidityProvidersOnPool[key].push(timeCommitment.liquidityProvider);
        emit NewTimeCommitment(
            timeCommitment.liquidityProvider,
            poolId,
            lpPositionKey,
            timeCommitments[lpPositionKey][poolId]
        );
        return IHooks.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override(BaseHook) onlyPoolManager returns (bytes4) {
        address liquidityProvider = 
        if (!(isLiquidityWithdrawable(lpPositionKey, poolId)))
            revert LockedLiquidity();
        return IHooks.beforeRemoveLiquidity.selector;
    }

    function isLiquidityWithdrawable(
        bytes32 lpPositionKey,
        PoolId poolId
    ) internal view returns (bool isWithdrawable) {
        isWithdrawable = (block.number >=
            timeCommitments[lpPositionKey][poolId].startingBlockNumber +
                timeCommitments[lpPositionKey][poolId].numberOfBlocks);
    }

    function getPositionPoolTimeCommitment(
        bytes32 lpPositionKey,
        PoolId poolId
    ) public view returns (TimeCommitment memory timeCommitment) {
        timeCommitment = timeCommitments[lpPositionKey][poolId];
    }

    function getTimeCommitmentKeys(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params
    ) public returns (bytes32 lpPositionKey, PoolId poolId) {
        poolId = key.toId();
        lpPositionKey = sender.calculatePositionKey(
            params.tickLower,
            params.tickUpper,
            params.salt
        );
    }


}
