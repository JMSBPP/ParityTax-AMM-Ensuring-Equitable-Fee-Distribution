// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {ITaxController} from "../interfaces/ITaxController.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";


// TODO: The TaxController needs to be a DonateRouter to credit the PLP's
abstract contract TaxControllerBase is ITaxController{

    function _getJitTaxLiability(BalanceDelta jitFeeRevenueDelta) internal returns (BalanceDelta){

    }

    function _getPlpTaxCredit(uint256 plpPositionTokenId) internal returns(BalanceDelta){

    }

    
}