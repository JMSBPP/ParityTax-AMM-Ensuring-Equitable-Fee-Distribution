// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolOperation.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {Position} from "v4-core/libraries/Position.sol";
import {IHooks} from "v4-core/interfaces/IHooks.sol";

struct TimeCommitmentParams {
    bool longTerm;
    uint256 numberOfBlocks;
    uint256 startingBlockNumber;
}
struct TimeCommitment {
    address owner;
    TimeCommitmentParams timeCommitmentParams;
    ModifyLiquidityParams liquidityParams;
}

contract LiquidityTimeCommitmentHook is BaseHook {
    using Position for address;
    IPoolManager public immutable manager;

    error LockedLiquidity();

    mapping(bytes32 positionKey => TimeCommitment) public timeCommitments;
    //One owner can have multiple positions
    mapping(address sender => bytes32 positionKey) public positionOwned;

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
    ) external override(BaseHook) onlyPoolManager returns (bytes4) {
        // With valid we mean that it decodes to a TimeCommitmentParams
        TimeCommitmentParams memory timeCommitmentParams = abi.decode(
            hookData,
            (TimeCommitmentParams)
        );
        TimeCommitment memory timeCommitment = TimeCommitment({
            owner: sender,
            timeCommitmentParams: timeCommitmentParams,
            liquidityParams: params
        });

        manager.unlock(abi.encode(timeCommitment));

        return IHooks.beforeAddLiquidity.selector;
    }

    function unlockCallback(
        bytes memory rawData
    ) external onlyPoolManager returns (bytes memory res) {
        TimeCommitment memory timeCommitment = abi.decode(
            rawData,
            (TimeCommitment)
        );

        setLiquidityWithdrawalLock(timeCommitment);

        res = "";
    }

    function setLiquidityWithdrawalLock(
        TimeCommitment memory timeCommitment
    ) internal {
        if (timeCommitment.timeCommitmentParams.longTerm) {
            //We get the respective positionKey
            // 1. Who is the owner of the position ?
            // 1.1 Is it msg.sender ?
            bytes32 positionKey = timeCommitment.owner.calculatePositionKey(
                timeCommitment.liquidityParams.tickLower,
                timeCommitment.liquidityParams.tickUpper,
                timeCommitment.liquidityParams.salt
            );

            positionOwned[timeCommitment.owner] = positionKey;
            timeCommitments[positionKey] = timeCommitment;
        }
    }

    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData
    ) external override(BaseHook) onlyPoolManager returns (bytes4) {
        bytes32 positionKey = positionOwned[sender];
        if (!(isLiquidityWithdrawable(positionKey))) revert LockedLiquidity();
    }

    function isLiquidityWithdrawable(
        bytes32 positionKey
    ) internal returns (bool isWithdrawable) {
        TimeCommitment memory timeCommitment = timeCommitments[positionKey];
        isWithdrawable =
            block.number >=
            timeCommitment.timeCommitmentParams.startingBlockNumber +
                timeCommitment.timeCommitmentParams.numberOfBlocks;
    }
}
