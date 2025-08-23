// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";


// TODO: This needs to inherit IERC4626

interface ITaxController {

    function taxJITFeeRevenue(BalanceDelta totalFees) external returns(BalanceDelta);    
}
