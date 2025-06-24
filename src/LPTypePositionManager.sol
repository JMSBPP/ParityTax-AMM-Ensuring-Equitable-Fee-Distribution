// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILPTypePositionManager} from "./interfaces/ILPTypePositionManager.sol";
import {ILiquidityOperator} from "./hooks/interfaces/ILiquidityOperator.sol";

import {PositionManager} from "v4-periphery/src/PositionManager.sol";

abstract contract LPTypePositionManager is
    PositionManager,
    ILPTypePositionManager
{
    //NOTE: Each liquidity position, which essentially is
    // a price range on a pool where liquidity will be supplied
    // has amn operator thaat excecutes the way this liquidity is
    // managed depending of the type of LP
    mapping(uint256 tokenId => ILiquidityOperator)
        private LPTypeLiquidityOperator;
}
