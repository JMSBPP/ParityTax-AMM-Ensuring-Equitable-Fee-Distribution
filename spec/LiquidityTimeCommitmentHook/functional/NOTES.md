## `ADD-LIQUIDITY`

- The `LiquidityTimeCommitmentRouter` **calls** the `modifyLiquidity` on the `PoolManager`.
- The `PoolManager` **calls** the `Pool.modifyLiquidity` which returns the `LiquidityDelta`
- The `PoolManager` **calls** the `LiquidityTimeCommitmentHook.afterAddLiquidity` passing the
`liquidityDelta` and the `LiquidityTimeCommitmentData`

> NOTE The `LiquidityTimeCommitmentHook` has `afterAddLiquidityReturnDelta` enabled

- The `LiquidityTimeCommitmentHook.afterAddLiquidity` **delegatecalls** to the `LiquidityOperatorHook.afterAddLiquidity`. This ensures that `msg.sender = PoolManager` which for consitency also has  `afterAddLiquidityReturnDelta` enabled

