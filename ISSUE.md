
# Description

- See if one can use the NonZero library inside the beforeAddLiquidity to emit the 
BalanceDelta as an event just for debugging purposes ...

- Refer to the overall functional requirement associated with the test

- Refer to the `ADD_LIQUIDITY FLOW` to explain expected behaviour
- explain possible reasons why I think is not working

When running 

```sh
forge test --match-contract LiquidityTimeCommitmenUnitHookTest --mt test__beforeAddLiquidity__shouldRouteToJITLiquidityManager
```

Test is reverting and outputting a `CurrencyNotSettled()` error. This seems to be because when the `PoolManager` is to `Lock`, the callback's `NonZeroDelta` shows that there is a non-zero `BalanceDelta`. My hint is that for the intentions of this hook, one might need to use the `afterAddLiquidityReturnDelta` flag. This is because the liquidity is stored on the `PoolManager` by liquidity token claims, and are aimed to be handled by the `LiquidityManager` using `LiquidityAccounting` for managing funds using `ERC4626` vaults.

