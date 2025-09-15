// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import {IReactive} from "@reactive-network/interfaces/IReactive.sol";
import {IFiscalPolicy} from "../interfaces/IFiscalPolicy.sol";
import "../types/Shared.sol";
import "./ParityTaxHookSubscriptions.sol";

import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";


library FiscalLogDispatcher{


// struct PriceImpactCallback{
//     SwapIntent swapIntent;
//     BalanceDelta swapDelta;
//     uint160 beforeSwapSqrtPriceX96;
//     uint160 beforeSwapExternalSqrtPriceX96;
//     uint160 afterSwapSqrtPriceX96;
//     uint160 afterSwapExternalSqrtPriceX96;
// }

    
    //TODO: Implement the other dispatching cases
    function dispatch(
        IReactive.LogRecord memory log
    ) internal returns(bytes memory){
        if (log.topic_0 == PRICE_IMPACT_TOPIC0){
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
            PoolId poolId = PoolId.wrap(bytes32(log.topic_1));
            PriceImpactCallback memory priceImpactCallback = PriceImpactCallback(
                uint48(log.block_number),
                swapIntent,
                swapDelta,
                beforeSwapSqrtPriceX96,
                beforeSwapExternalSqrtPriceX96,
                afterSwapSqrtPriceX96,
                afterSwapExternalSqrtPriceX96
            );

            bytes memory callbackData = abi.encodeCall(
                IFiscalPolicy.calculateOptimalTax,
                (
                    poolId,
                    abi.encode(priceImpactCallback)
                )
            );

            return callbackData;
            
        }
    }


}