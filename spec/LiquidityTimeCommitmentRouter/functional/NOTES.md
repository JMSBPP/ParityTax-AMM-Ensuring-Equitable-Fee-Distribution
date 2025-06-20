# `LiquidityTimeCommitmmentRouter`


## `EOA LP modifyLiquidity`


### `modifyLiquidity`
- `EOA LP`  sends `modifiyLiquidityParams` along with encoded `timeCommitment` data to `modifyLiquidity` on `LiquidityTimeCommitmentRouter`

-  `LiquidityTimeCommitmentRouter.modifyLiquidity` does the following:

   -  Decodes the `timeCommitment`
   -  Queries the `LiquidityTimeCommitmentManager` for the following:
      
      -  retreive the `EOA LP.liquidity type` (a.k.a `JIT, PLP` or `NONE`)
      
      -  If the upcoming `EOA LP.liquidityType` matches the  existing  `EOA LP.liquidityType`:
      -    build the `LiquidityTimeCommitmentData`
      -    encode the  `LiquidityTimeCommitmentData`
      -    send to `poolManager.unlock(encodedLiquidityTimeCommitmentData)`:

## `_unlockCallback`
### Assumptions

- The underlying `EOA LP.liquidityType` are checked

### Flow

- if `liquidityTimeCommitmentData.liquidityParams.liquidityDelta > 0` `liquidityAction.ADD_LIQUIDITY`
  
    - get the underlying `LiquidityOperator` from 
    the `LiquidityTimeCommitmentManager`
    - Perform the `pool.modifyLiquidity= liquidityDelta`
    - Gte the `liquidityDeltas` from the resulting `liquidityDelta`
    - `settle` the deltas not using burn ( a.k.a transfer funds to the `poolManager`)
    - `take` the deltas using `takeClaims` from the 
    `poolManager` to the `liquidityOperator`
### Output
- The `poolManager` should have the balances of the 
`currencies` for the liquidity added
- The `liquidityOperator` should have the equivalent
mintable tokens for the liquidity added