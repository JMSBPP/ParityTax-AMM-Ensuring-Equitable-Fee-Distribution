// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "v4-periphery/src/interfaces/IPositionManager.sol";
import "../../interfaces/ITaxController.sol";
import {ITradingFeeRevenueDB} from "../../interfaces/ITradingFeeRevenueDB.sol";

//NOTE: Subject independenlty of the LP-Type
// the operator
// - Manages the asosciated liquidity claim tokens associated with the LP-Positions
interface ILiquidityOperator {
    function getPositionManager() external view returns (IPositionManager);
}
