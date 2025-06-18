# `LiquidityTimeCommitmmentRouter`

- LiquidityTimeCommitment is better enforced from _routers_ specifying the commmitment in `callback` data

- After this `liquidityTimeCommitmentRouter` sends the `callBackData`  to the `poolManager`, from this point on because the `poolManager` is _immutable_ , it forwards the `LiquidityTimeCommitmentData` to the `LiquidityCommitmentClassifier` where `beforeAddLiquidity` will be in charge of routing the `LiquidityTimeCommitmentData` accordingly.


> Not special mechanism is done for traders then the router is only for modifyLiquidity.

