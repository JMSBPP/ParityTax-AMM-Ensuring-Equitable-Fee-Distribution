// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Multicallable} from "solady/utils/Multicallable.sol";

import {AbstractReactive} from "@reactive-network/abstract-base/AbstractReactive.sol";
import {IReactive} from "@reactive-network/interfaces/IReactive.sol";

import {IParityTaxHook} from "./interfaces/IParityTaxHook.sol";
import {IFiscalPolicy} from "./interfaces/IFiscalPolicy.sol";
import {ISystemContract} from "@reactive-network/interfaces/ISystemContract.sol";


import "./types/Shared.sol";

import "./libraries/SubscriptionBatchCall.sol";
import "./libraries/FiscalLogDispatcher.sol";


abstract contract FiscalListeningPost is AbstractReactive, Multicallable{
    using SubscriptionBatchCall for IParityTaxHook;
    using FiscalLogDispatcher for IReactive.LogRecord;

    uint64 private constant GAS_LIMIT = 10000000;
    

    IFiscalPolicy fiscalPolicy; 


    constructor(
        uint256 chainId,
        IParityTaxHook _parityTaxHook,
        IFiscalPolicy _fiscalPolicy
    ){
        (bool success,) = _parityTaxHook.batchExecuteSubscriptions(
            chainId,
            address(service)
        );
        vm = !success;

        fiscalPolicy = _fiscalPolicy;
    }


    function react(
        LogRecord calldata log
    )external vmOnly {
        bytes memory data = log.dispatch();
        emit Callback(
            log.chain_id,
            address(fiscalPolicy),
            GAS_LIMIT,
            data     
        );
    }


}



