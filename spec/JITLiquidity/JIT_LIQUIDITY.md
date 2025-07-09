## Results:
- Uniswap v3 supported over $\$600 \, \text{bn}$ of trading
volume in the same period, meaning that JIT liquidity filled $0.3\%$ of all liquidity
demand.

- JIT liquidity has historically been concentrated
across the top pools on Uniswap by trading volume --> __This outlies the issue that JIT improving price quality is limited to stable pools__. (__The top ten pools account for 95%. On the demand side, the top 10 pools account for just 55% of
total trading volume.__)

- **JIT transactions are only profitable
when the swap in the middle is large enough, and large trades are much more
concentrated in the top pools**
### Questions
- How to incentivize JIT on volatile pools?
  - **Hint:**  pairs in large
pools have greater liquidity on centralized exchange venues, making the hedging
transaction much easier and cheaper to complete. $\to$ Create alternative relaibale hedging mechanism for volatile pools.
## Advantages:
- With Hooks JIT's save the cost of paying miners, because their liquidity is guranteed on `afterSwap`
-    
$\partial_{\mathcal{L}^{\text{\texttt{JIT}}}} C^{\text{\texttt{slippage}}} \leq 2\cdot \phi^M$
- $\mathcal{L}^{\text{\texttt{JIT}}} \bigg ( \big [i^{\text{\texttt{swap}}}_{l}, i^{\text{\texttt{swap}}}_{u} \big ] \bigg ) + \text{\texttt{hedging}}$
- Integration with `flashbots`

## `beforeSwap`

```json
{
    "beforeSwap.preConditions":[
        {
            "name":"expectedProfit is positive",
            "description": {
                "liquidityDelta*fee - addRemoveLiquidityGasCost
                >= swapDelta*(slippage - fee) - swapGasCost",
                "2*fee > slippage"
            }
        },
        
    ]
}
{
    "beforeSwap.postConditions": [
        {
            "description:": "addLiquidity.blockNumber==removeLiquidity.blockNumber"
        },
        {
            "description": "removeLiquidity.nonce == swap.nonce + addLiquidity.nonce"
        }
    ],
    "beforeSwap.logic":[
        {
            "name": "computeDifference",
            "description": {
                "1": "uint256 quoteTokenProfit =addedLiquidityDelta.amount0() - removedLiquidityDelta.amount0()",

            }

        }
    ]
}
```