// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import {IReactive} from "@reactive-network/interfaces/IReactive.sol";
import {IFiscalPolicy} from "../interfaces/IFiscalPolicy.sol";
import "../types/Shared.sol";
import "./ParityTaxHookSubscriptions.sol";

import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";


/**
 * @title FiscalLogDispatcher
 * @author ParityTax Team
 * @notice Library for dispatching ParityTax hook events to fiscal policy callbacks
 * @dev This library is a critical component of the reactive network architecture, responsible for
 * parsing and transforming log records from IParityTaxHook events into structured callback data
 * that can be sent to IFiscalPolicy for optimal tax calculations. It handles the conversion of
 * raw event data into specific callback formats based on event types.
 * @dev Currently implements dispatching for PriceImpact events, with TODO for other event types
 */
library FiscalLogDispatcher{


    /**
     * @notice Struct for PriceImpact event callback data
     * @dev Contains all the data from a PriceImpact event that needs to be forwarded to the fiscal policy
     * for optimal tax calculation. This struct is used to encode callback data for the reactive network.
     * @dev Currently commented out as it's defined in ParityTaxHookSubscriptions.sol
     */
    // struct PriceImpactCallback{
    //     SwapIntent swapIntent;
    //     BalanceDelta swapDelta;
    //     uint160 beforeSwapSqrtPriceX96;
    //     uint160 beforeSwapExternalSqrtPriceX96;
    //     uint160 afterSwapSqrtPriceX96;
    //     uint160 afterSwapExternalSqrtPriceX96;
    // }

    /**
     * @notice Dispatches log records from ParityTax hook events to fiscal policy callbacks
     * @dev This is the main dispatch function that parses incoming log records and converts them
     * into structured callback data for the fiscal policy. It handles different event types by
     * checking the topic0 and decoding the appropriate data structure.
     * @dev Currently implements dispatching for PriceImpact events, with TODO for other event types
     * @param log The log record from the reactive network containing ParityTax hook event data
     * @return callbackData The encoded callback data to be sent to the fiscal policy
     * @dev TODO: Implement the other dispatching cases for additional event types
     */
    function dispatch(
        IReactive.LogRecord memory log
    ) internal returns(bytes memory){
        if (log.topic_0 == PRICE_IMPACT_TOPIC0){
            // Decode PriceImpact event data from the log record
            (
                SwapIntent swapIntent,
                BalanceDelta swapDelta,
                uint160 beforeSwapSqrtPriceX96,
                uint160 beforeSwapExternalSqrtPriceX96,
                uint160 afterSwapSqrtPriceX96,
                uint160 afterSwapExternalSqrtPriceX96

            ) = abi.decode(
                log.data,
                (
                    SwapIntent,
                    BalanceDelta,
                    uint160,
                    uint160,
                    uint160,
                    uint160
                )
            
            );
            
            // Extract pool ID from topic1 of the log record
            PoolId poolId = PoolId.wrap(bytes32(log.topic_1));
            
            // Create PriceImpactCallback struct with decoded data and block number
            PriceImpactCallback memory priceImpactCallback = PriceImpactCallback(
                uint48(log.block_number),
                swapIntent,
                swapDelta,
                beforeSwapSqrtPriceX96,
                beforeSwapExternalSqrtPriceX96,
                afterSwapSqrtPriceX96,
                afterSwapExternalSqrtPriceX96
            );

            // Encode callback data for IFiscalPolicy.onPriceImpact function
            bytes memory callbackData = abi.encodeCall(
                IFiscalPolicy.onPriceImpact,
                (
                    poolId,
                    abi.encode(priceImpactCallback)
                )
            );

            return callbackData;
            
        } else if (log.topic_0 == LIQUIDITY_ON_SWAP_TOPIC0){
            // Decode LiquidityOnSwap event data from the log record
            (
                uint128 totalLiquidity,
                uint128 jitLiquidity,
                uint128 plpLiquidity
            ) = abi.decode(log.data, (uint128, uint128, uint128));

            // Extract pool ID from topic1 of the log record
            PoolId poolId = PoolId.wrap(bytes32(log.topic_1));

            // Create LiquidityOnSwapCallback struct with decoded data and block number
            LiquidityOnSwapCallback memory liquidityOnSwapCallback = LiquidityOnSwapCallback(
                uint48(log.block_number),
                totalLiquidity,
                jitLiquidity,
                plpLiquidity
            );
            bytes memory callbackData = abi.encodeCall(
                IFiscalPolicy.onLiquidityOnSwap,
                (
                    poolId,
                    abi.encode(liquidityOnSwapCallback)
                )
            );

            return callbackData;
        }
    }


}