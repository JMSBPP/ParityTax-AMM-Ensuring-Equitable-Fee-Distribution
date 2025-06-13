// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "v4-core/types/PoolKey.sol";
import "v4-core/types/PoolId.sol";
import {ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import "v4-core/types/BalanceDelta.sol";
import {SafeCast} from "v4-core/libraries/SafeCast.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {Position} from "v4-core/libraries/Position.sol";
import "./types/LiquidityTimeCommitmentData.sol";

import "v4-periphery/src/base/BaseActionsRouter.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";

abstract contract LiquidityTimeCommitmentManager is BaseActionsRouter {
    using SafeCast for *;
    using PoolIdLibrary for PoolKey;
    using TimeCommitmentLibrary for TimeCommitment;
    using TimeCommitmentLibrary for bytes;
    using StateLibrary for IPoolManager;
    using SqrtPriceMath for uint160;
    using TickMath for int24;
    using BalanceDeltaLibrary for BalanceDelta;

    // NOTE:

    //     The positionKey already contains the lpAddress
    //     and add's to other information through the use of the
    //      Position Library.

    //       Additionally the TimeCommitment has also its own services defined through the TimeCommitmnetLibrary

    mapping(bytes32 positionKey => TimeCommitment) liquidityTimeCommitments;
    // NOTE:
    //     The positon manager for traditional liquidity actions is CONTROLLED by the
    ///     LiquidityTimeCommitmentManager

    //  It can be updtaded under certain conditions to other PositionManagers (this is to be guarded)
    IPositionManager private positionManager;
    constructor(
        IPoolManager _manager,
        IPositionManager initialPositionManager
    ) BaseActionsRouter(_manager) {
        setPositionManager(initialPositionManager);
    }

    //TODO: How this function is protected ?
    function setPositionManager(IPositionManager _positionManager) internal {
        positionManager = _positionManager;
    }
    //NOTE:

    // We need to define actions for JIT, PLP modifying liquidity
    // and revenue and tax mechanisms
    function _handleAction(
        uint256 action,
        bytes calldata params
    ) internal override(BaseActionsRouter) {
        //TODO: We define settleLiquidity as an action and it's parameters
        // and route to the setttlliquidity internal function which performs the
        // logic
    }

    function settleLiquidity(
        PoolKey calldata poolKey,
        ModifyLiquidityParams calldata params
    ) internal {
        (uint160 currentSqrtPriceX96, , , ) = poolManager.getSlot0(
            poolKey.toId()
        );
        // function getAmount0Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity, bool roundUp)
        //     internal
        //     pure
        //     returns (uint256)

        BalanceDelta liquidityDelta = toBalanceDelta(
            currentSqrtPriceX96
                .getAmount0Delta(
                    params.tickUpper.getSqrtPriceAtTick(),
                    params.liquidityDelta,
                    true
                )
                .toInt128(),
            currentSqrtPriceX96
                .getAmount1Delta(
                    params.tickLower.getSqrtPriceAtTick(),
                    params.liquidityDelta,
                    true
                )
                .toInt128()
        );

        (int128 liquidityOnCurrency0, int128 liquidityOnCurrency1) = (
            liquidityDelta.amount0(),
            liquidityDelta.amount1()
        );

        // transferring liquidity to the pool
        poolManager.burn(
            poolKey.currency0,
            address(this),
            liquidityOnCurrency0
        );
        poolManager.burn(
            poolKey.currency1,
            address(this), //NOTE: This NEEDS to be right JIT/PLP
            // LiquidityManager
            liquidityOnCurrency1
        );

        // TODO:
        //     Once the liquidity is claimed by the corresponding
        //     JIT/PLP_LiquidityManager:
        //    --> Is the JIT/PLP_LiquidityManager responsability
        //      to hanndle the liquidty based on the type of LP
        //    either send it to be managed by JIT Hooks (i.e JIT LP type)
        //    or send it to be managed by PLP vaults (i.e PLP LP type)
    }
}
