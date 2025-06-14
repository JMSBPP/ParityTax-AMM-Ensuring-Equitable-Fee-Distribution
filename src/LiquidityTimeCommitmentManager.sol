// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolId.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "v4-core/types/BalanceDelta.sol";
import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "v4-core/types/Currency.sol";

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {Position} from "v4-core/libraries/Position.sol";
import "./types/LiquidityTimeCommitmentData.sol";

import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {ImmutableState} from "v4-periphery/src/base/ImmutableState.sol";
import {ILiquidityOperator} from "./interfaces/ILiquidityOperator.sol";
import {IPLPLiquidityOperator} from "./interfaces/IPLPLiquidityOperator.sol";
import {IJITLiquidityOperator} from "./interfaces/IJITLiquidityOperator.sol";

import {LiquidityTimeCommitmentActions} from "./libs/LiquidityTimeCommitmentActions.sol";
import {ILiquidityTimeCommitmentManager} from "./interfaces/ILiquidityTimeCommitmentManager.sol";

error InvalidTimeCommitment___NoCommitmentAssociatedWithPosition();

abstract contract LiquidityTimeCommitmentManager is
    ILiquidityTimeCommitmentManager,
    ImmutableState
{
    using SafeCast for *;
    using PoolIdLibrary for PoolKey;
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
    using StateLibrary for IPoolManager;
    using SqrtPriceMath for uint160;
    using TickMath for int24;
    using BalanceDeltaLibrary for BalanceDelta;
    using CurrencyLibrary for Currency;
    using CurrencyLibrary for uint256;
    // NOTE:

    //     The positionKey already contains the lpAddress
    //     and add's to other information through the use of the
    //      Position Library.

    //       Additionally the TimeCommitment has also its own services defined through the TimeCommitmnetLibrary

    // mapping(bytes32 positionKey => TimeCommitment)
    //     private liquidityTimeCommitments;

    mapping(bytes32 positionKey => IPLPLiquidityOperator)
        private plpLiquidityOperators;
    mapping(bytes32 positionKey => IJITLiquidityOperator)
        private jitLiquidityOperators;

    // NOTE:
    //     The positon manager for traditional liquidity actions is CONTROLLED by the
    ///     LiquidityTimeCommitmentManager

    //  It can be updtaded under certain conditions to other PositionManagers (this is to be guarded)
    IPositionManager private positionManager;

    constructor(
        IPoolManager _manager,
        IPositionManager initialPositionManager
    ) ImmutableState(_manager) {
        setPositionManager(initialPositionManager);
    }

    //TODO: How are thesse functions is protected ?
    function setPositionManager(IPositionManager _positionManager) internal {
        positionManager = _positionManager;
    }

    function setJITLiquidityOperator(
        bytes32 positionKey,
        IJITLiquidityOperator _jitLiquidityOperator
    ) internal {
        jitLiquidityOperators[positionKey] = _jitLiquidityOperator;
    }

    function setPLPLiquidityOperator(
        bytes32 positionKey,
        IPLPLiquidityOperator _plpLiquidityOperator
    ) internal {
        plpLiquidityOperators[positionKey] = _plpLiquidityOperator;
    }

    function getJITLiquidityOperator(
        bytes32 positionKey
    ) public view returns (IJITLiquidityOperator _jitLiquidityOperator) {
        _jitLiquidityOperator = jitLiquidityOperators[positionKey];
    }

    function getPLPLiquidityOperator(
        bytes32 positionKey
    ) external view returns (IPLPLiquidityOperator _plpLiquidityOperator) {
        _plpLiquidityOperator = plpLiquidityOperators[positionKey];
    }

    function getPositionTimeCommitment(
        bytes32 positionKey
    ) external view returns (TimeCommitment memory timeCommitment) {
        // TODO: We need to search on the JITOperator and PLPOperator
        // this is
        try
            plpLiquidityOperators[positionKey].getPositionTimeCommitment(
                positionKey
            )
        returns (TimeCommitment memory plpTimeCommitment) {
            timeCommitment = plpTimeCommitment;
        } catch (bytes memory reason) {
            if (
                keccak256(reason) ==
                keccak256("InvalidTimeCommitment__BlockAlreadyPassed()") ||
                keccak256(reason) ==
                keccak256(
                    "InvalidTimeCommitment__StartingBlockGreaterThanEndingBlock()"
                )
            ) {
                timeCommitment = jitLiquidityOperators[positionKey]
                    .getPositionTimeCommitment(positionKey);
            } else {
                // rethrow the error if it is not one of the expected errors
                revert InvalidTimeCommitment___NoCommitmentAssociatedWithPosition();
            }
        }
    }
    function getPositionLiquidityDelta(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams
    ) internal view returns (BalanceDelta liquidityDelta) {
        (uint160 currentSqrtPriceX96, , , ) = poolManager.getSlot0(
            poolKey.toId()
        );

        liquidityDelta = toBalanceDelta(
            SqrtPriceMath
                .getAmount0Delta(
                    currentSqrtPriceX96,
                    liquidityParams.tickLower.getSqrtPriceAtTick(),
                    liquidityParams.liquidityDelta.toInt128().toUint128(),
                    true
                )
                .toInt128(),
            SqrtPriceMath
                .getAmount1Delta(
                    currentSqrtPriceX96,
                    liquidityParams.tickUpper.getSqrtPriceAtTick(),
                    liquidityParams.liquidityDelta.toInt128().toUint128(),
                    true
                )
                .toInt128()
        );
    }
    function directLiquidity(
        PoolKey memory poolKey,
        ModifyLiquidityParams memory liquidityParams,
        bool isJIT,
        bytes32 liquidityPositionKey,
        TimeCommitment memory timeCommitment
    ) external {
        BalanceDelta liquidityDelta = getPositionLiquidityDelta(
            poolKey,
            liquidityParams
        );

        (int128 liquidityOnCurrency0, int128 liquidityOnCurrency1) = (
            liquidityDelta.amount0(),
            liquidityDelta.amount1()
        );

        // transferring liquidity to the pool
        if (isJIT) {
            poolManager.burn(
                address(jitLiquidityOperators[liquidityPositionKey]),
                poolKey.currency0.toId(),
                uint256(liquidityOnCurrency0.toUint128())
            );
            jitLiquidityOperators[liquidityPositionKey]
                .setPositionTimeCommitment(
                    liquidityPositionKey,
                    timeCommitment
                );
        }
        if (!isJIT) {
            poolManager.burn(
                address(plpLiquidityOperators[liquidityPositionKey]),
                poolKey.currency1.toId(),
                uint256(liquidityOnCurrency1.toUint128())
            );
            plpLiquidityOperators[liquidityPositionKey]
                .setPositionTimeCommitment(
                    liquidityPositionKey,
                    timeCommitment
                );
        }
    }
}
