// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "@openzeppelin/interfaces/IERC4626.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";


interface ITaxController is IERC4626{

    function taxJITFeeRevenue(BalanceDelta totalFees) external returns(BalanceDelta);    
}
