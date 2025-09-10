// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {ITaxController} from "../interfaces/ITaxController.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolId.sol";
// (poolId --> (commitment -->FeeRevenue[]))
//  --> bytes32 -> (uint256 --> uint256[])[]

// TODO: The TaxController needs to be a DonateRouter to credit the PLP's
abstract contract TaxControllerBase is ITaxController{

    function _getJitTaxLiability(BalanceDelta jitFeeRevenueDelta) internal returns (BalanceDelta){

    }

    function _getPlpTaxCredit(uint256 plpPositionTokenId) internal returns(BalanceDelta){

    }





    
}