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


/**
 * @title FiscalListeningPost
 * @author ParityTax Team
 * @notice Reactive network bridge contract for forwarding event data from ParityTax hooks to fiscal policy
 * @dev This contract serves as a critical component in the reactive network architecture, listening to events
 * from IParityTaxHook and forwarding them to IFiscalPolicy for optimal taxation calculations. It acts as a
 * real-time data pipeline that enables the fiscal policy to react to liquidity events, fee collections,
 * and swap activities to calculate and apply optimal tax rates.
 * @dev Inherits from AbstractReactive for reactive network integration and Multicallable for batch operations
 */
contract FiscalListeningPost is AbstractReactive{
    using SubscriptionBatchCall for IParityTaxHook;
    using FiscalLogDispatcher for IReactive.LogRecord;

    /// @notice Gas limit for reactive network callbacks to fiscal policy
    uint64 private constant GAS_LIMIT = 10000000;
    
    /// @notice The fiscal policy contract that receives forwarded event data for tax calculations
    IFiscalPolicy fiscalPolicy; 


    /**
     * @notice Initializes the FiscalListeningPost reactive network bridge
     * @dev Sets up the reactive network subscription to ParityTax hook events and configures the fiscal policy target.
     * The contract subscribes to events from the ParityTax hook system to enable real-time forwarding of
     * liquidity events, fee collections, and swap data to the fiscal policy for optimal tax calculations.
     * @param chainId The blockchain chain ID for the reactive network subscription
     * @param _parityTaxHook The ParityTax hook contract to listen for events from
     * @param _fiscalPolicy The fiscal policy contract that will receive forwarded event data
     */
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


    /**
     * @notice Reacts to ParityTax hook events and forwards them to the fiscal policy
     * @dev This is the core reactive network function that processes incoming log records from the ParityTax hook system.
     * It dispatches the event data through the FiscalLogDispatcher and emits a Callback event to trigger
     * the fiscal policy's tax calculation logic. This enables real-time response to liquidity events,
     * fee collections, and swap activities for optimal taxation.
     * @param log The log record containing event data from the ParityTax hook system
     * @dev This function is restricted to vmOnly to ensure only the reactive network can trigger it
     */
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



