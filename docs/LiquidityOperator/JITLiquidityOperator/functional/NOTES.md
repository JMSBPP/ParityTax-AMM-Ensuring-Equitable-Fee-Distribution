# `JITLiquidityOperator`

- We consider the flow that leads to the call of `JITLiquidityOperator` service, on one side this happens when `JIT` LP is adding liquidity.


- Notice that each position's `JITLiquidityOperator` holds the _token claims_ for both _currencies_ representing the liquidity available (including the one added) for a specific position, this is an lp and the associated pool. 

- The JITPositions are updated every block, where an LP can decide whether to _stop_ enabling JIT Liquidity or _continue_ it's **LiquidityTimeCommitment**

- As and add-on the LP can decide to vary the liquidity available on each time epoch, say for example an JIT LP, added some liquidity with time epoch $X$, the following happens:

   - For the position the liquidity is added 
   - But there shoukld be a mechanism for an informed JIT LP to specify contingent JIT liquidity on future blocks or conversely stop provideing liquidity contingent to callback data.
 
 - Let us consider the fisrt case where the JIT LP justa dds liquidity (a.k.a specifies a timeCommitment to its position).
- The question is where is it better to store the calime tokens for its liquidity? 

The thing is that the liquidity is adde3d through claims to the JITOperator, but how does it know that it belongs to apecified lp?
```solidity
contract LiquidityTimeCommitmentManager{
    
    mapping(bytes32 positionKey = > JITLiquidityOperatorKey) private JITLiquidityOperators
}

```
- With this every positon has it's own dedicated operator, so funds are distributed among all operators indexed by the position key, so ehach operator knows that the administrated funds belong to specific lp and are to service trading on a specifc pool.
