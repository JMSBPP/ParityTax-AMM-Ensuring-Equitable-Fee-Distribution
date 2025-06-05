// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
// ======POOL MANAGER RELATED =======
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolId.sol";
import "v4-core/types/PoolOperation.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Position} from "v4-core/libraries/Position.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";

//=========OWN RELATED =======

//======POSITION MANAGER RELATED =============

struct TimeCommitment {
    address liquidityProvider;
    bool longTerm;
    uint256 numberOfBlocks;
    uint256 startingBlockNumber;
}
// lp -> liquidityRouter -> poolManager -> hook
//msg.sender == PoolManager
// sender == liquidityRouter
// How do I find the underlying
//liquidity Provider address
//TODO: We must deal with
// 1  Can someone call the router from a
//    different address and still withdraw?
// 1.1. Can the sender which is the
//      on beforeRemoveLiquidity(sender, ...)
//     router be asked which is the lp
//     from the sender attribute?
// 2. How to integrate this more efficiently with the position
//    manager ?

contract LiquidityTimeCommitmentHook is BaseHook {
    using Position for address;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for *;

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
        TimeCommitment memory timeCommitment = abi.decode(
            hookData,
            (TimeCommitment)
        );

        (bytes32 lpPositionKey, PoolId poolId) = getTimeCommitmentKeys(
            timeCommitment.liquidityProvider,
            key,
            params
        );

        timeCommitments[lpPositionKey][poolId] = timeCommitment;

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
        // this needs to be the lp that originated teh call to the router
        // TODO:
        // Can someone call the router from a different address and still withdraw?
        // Or can the sender which is the router be asked which is the lp?
        address liquidityProvider = abi.decode(hookData, (address));

        (bytes32 lpPositionKey, PoolId poolId) = getTimeCommitmentKeys(
            liquidityProvider,
            key,
            params
        );
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
    ) public pure returns (bytes32 lpPositionKey, PoolId poolId) {
        poolId = key.toId();
        lpPositionKey = sender.calculatePositionKey(
            params.tickLower,
            params.tickUpper,
            params.salt
        );
    }
}
