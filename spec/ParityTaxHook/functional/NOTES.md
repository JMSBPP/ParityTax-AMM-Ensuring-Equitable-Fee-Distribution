
# LIQUIDITY FLOW

## `ADDING LIQUIDITY`

- Essentially on a general purpose modifyLiquidityRouter the user
only needs to specify the lpType and the endingBlock:


- The `ParityTaxHook.afterAddLiquidity` **receives** hookData and decodes it to an lpType, endingBlock pair.
__(The `PoolManager` has a debit of the liquidity added by the general purpose modifyLiquidityRouter caller (a.k.a liquiquidityProvider sender))__

- [`ParityTaxHook.afterAddLiquidityReturnDelta==true`]`ParityTaxHook.afterAddLiquidity` **assigns** the `sender = generalPurposeRouter` delta to itself such that router does not owe anything to the `PoolManager` but the debt is transfered to the `ParityTaxHook`. (`parityTaxLiquidityDelta = delta`)

- [`hookData.lpType`]`ParityTaxHook.afterAddLiquidity` asks the `PositionManage` to **approve** the `parityTaxLiquidityDelta` **amounts** to the corresponding `LPTypeLiquidityerator`

- [`hookData.lpType`]`ParityTaxHook.afterAddLiquidity` **stores** the underlying timeCommitment
on the `mapping(uint256 tokenId => mapping(PositionInfo => TimeCommitment))`

-  `ParityTaxHook.afterAddLiquidity` **settles** the __debt__ with the `PoolManager` on behalf of the `LPTypeLiquidityOperator`










Based on the lpType and timeCommitment passed by the caller once the liquidity is **added** the `ParityTaxHook.afterAddLiquidity`
checks is the hookData wheter the hookData is compliant or not:

The checks that `ParityTaxHook.afterAddLiquidity` does are

- It first derives the valid (lpType, endingBlock)

- Based on the lpType it maps to the corresponding liquidityOperator (PLP, JIT)

- It verifies that the address provided by the user has allowance for the liquidityDelta amounts on the `ParityTaxHook.afterAddLiquidity` params to actually provide liquidity   


Then the `_executeActions` forwards the `callbackData` to the poolManager to `unlock` it 
- If the LPTimeCommitment.LPType decodes to a number higher than 2, it is set at two
-  For `lpType = LPType.JIT` `endingBlock` can be arbitrary as it the
timeCommitment will enforce `endingBlock=block.number`


- For `lpType = LPType.PLP` There exists an `optimalEndingBlock` publicly visible such that any specified `endingBlock > optimalEndingBlock`, `endingBlock = block.number + optimalEndingBlock`


> NOTE: `Optimal duration` is adapted and PLP's providing liquidity on that duration will be further rewarded.

### `REMOVE LIQUIDITY`

- The address removing the liquidity (a.k.a `msg.sender`) needs to be an authorized address for the `liquidityOperator` or the default address that initiated the position, othewise the call reverts  when calling 
__adding liquidity__

- Any `hookData` passed is to be ignored but does not cause the call to revert.


## Swappers

- Any `PoolSwapRouter` can be hooked with `ParityTax`. All `hookData` passed on `poolManager.swap` to be ignored by the `ParityTaxHook`

- All swap calls are routed from the `ParityTaxHook` to the `JITTaxableHook` where `beforeSwap, afterSwap` logic takes place __('hookData' passed to the JITTaxableHook)__ is obtained inside the `ParityTaxHook.beforeSwap` logic flow.

## Conclusion:

- Any router which gives any hookData with lenght > 0 can integrate with the `ParityTax Hook`