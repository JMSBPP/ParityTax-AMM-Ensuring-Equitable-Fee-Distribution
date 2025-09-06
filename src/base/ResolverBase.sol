// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {
    LiquidityOperations,
    Planner,
    Plan,
    PositionConfig,
    LiquidityAmounts,
    Actions
} from "@uniswap/v4-periphery/test/shared/LiquidityOperations.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {ImmutableState} from "@uniswap/v4-periphery/src/base/ImmutableState.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

abstract contract ResolverBase is LiquidityOperations, ImmutableState{
    using Planner for Plan;

    constructor(
        IPoolManager _poolManager,
        IPositionManager _lpm
    ) ImmutableState(_poolManager){
        lpm = _lpm;

    }


     function _mintUnlocked(
        PositionConfig memory config,
        uint256 liquidity,
        address recipient,
        bytes memory hookData
    ) internal virtual {
        Plan memory planner = Planner.init();
        {
            planner.add(
                Actions.MINT_POSITION,
                abi.encode(
                    config.poolKey,
                    config.tickLower < config.tickUpper ?config.tickLower:config.tickUpper,
                    config.tickLower < config.tickUpper ?config.tickUpper:config.tickLower,
                    liquidity,
                    MAX_SLIPPAGE_INCREASE,
                    MAX_SLIPPAGE_INCREASE,
                    recipient,
                    hookData
                )
            );
            planner.add(
                Actions.CLOSE_CURRENCY,
                abi.encode(config.poolKey.currency0)
            );
            planner.add(
                Actions.CLOSE_CURRENCY, abi.encode(config.poolKey.currency1)
            );
        }
        
        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }

    function _burnUnlocked(
        uint256 tokenId,
        PositionConfig memory config
    ) internal virtual {
        Plan memory planner = Planner.init();
        planner.add(
            Actions.BURN_POSITION,
            abi.encode(
                tokenId,
                MIN_SLIPPAGE_DECREASE,
                MIN_SLIPPAGE_DECREASE,
                Constants.ZERO_BYTES
            )
        );

        planner.add(
            Actions.CLOSE_CURRENCY,
            abi.encode(config.poolKey.currency0)
        );
        planner.add(
            Actions.CLOSE_CURRENCY, 
            abi.encode(config.poolKey.currency1)
        );

        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }

    function _decreaseUnlocked(
        uint256 tokenId,
        PositionConfig memory config,
        uint256 liquidityToRemove
    ) internal virtual {
        Plan memory planner = Planner.init();
        planner.add(
            Actions.DECREASE_LIQUIDITY, 
            abi.encode(
                tokenId,
                liquidityToRemove,
                MIN_SLIPPAGE_DECREASE,
                MIN_SLIPPAGE_DECREASE,
                Constants.ZERO_BYTES
            )
        );

        planner.add(
            Actions.CLOSE_CURRENCY,
            abi.encode(config.poolKey.currency0)
        );
        
        planner.add(
            Actions.CLOSE_CURRENCY, 
            abi.encode(config.poolKey.currency1)
        );

        lpm.modifyLiquiditiesWithoutUnlock(planner.actions, planner.params);
    }
}
