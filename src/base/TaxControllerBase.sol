// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../interfaces/ITaxController.sol";
import {FeeRevenueInfoLibrary} from "../types/FeeRevenueInfo.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {PoolKey,PoolId,PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
// (poolId --> (commitment -->FeeRevenue[]))
//  --> bytes32 -> (uint256 --> uint256[])[]

// TODO: The TaxController needs to be a DonateRouter to credit the PLP's


import {ILPOracle} from "../interfaces/ILPOracle.sol";
import {IParityTaxRouter} from "../interfaces/IParityTaxRouter.sol";

abstract contract TaxControllerBase is ITaxController{
    using PoolIdLibrary for PoolKey;
    using FeeRevenueInfoLibrary for FeeRevenueInfo;


    ILPOracle _lpOracle;
    IParityTaxRouter  _router;

    constructor(
        ILPOracle __lpOracle,
        IParityTaxRouter __router
    )
    {
        _lpOracle = __lpOracle;
        _router = __router;
    }

    function _getJitTaxLiability(BalanceDelta jitFeeRevenueDelta) internal returns (BalanceDelta){

    }

    function _getPlpTaxCredit(uint256 plpPositionTokenId) internal returns(BalanceDelta){

    }

    function filTaxReport(PoolKey memory poolKey,FeeRevenueInfo feeRevenueInfo) external{
        PoolId poolId = poolKey.toId();
        emit TaxFiling (
            PoolId.unwrap(poolId),
            feeRevenueInfo.startBlock(),
            feeRevenueInfo.commitment(),
            feeRevenueInfo.toBalanceDelta()           
        );
        _filTaxReport(poolKey, feeRevenueInfo);
    }

    function _filTaxReport(PoolKey memory,FeeRevenueInfo) internal virtual{

    }

    function router() external returns(IParityTaxRouter){
        return _router;
    }


    function lpOracle() external returns(ILPOracle){
        return _lpOracle;
    }






    
}