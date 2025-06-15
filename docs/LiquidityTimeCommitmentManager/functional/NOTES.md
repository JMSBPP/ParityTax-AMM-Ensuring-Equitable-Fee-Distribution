# `LiquidityTimeCommitmentManager`


## Introduction
- They receive the following data from the `liquidityCommitmentClassifier.beforeAddLiquidity`:

- The information available to be passed to other entities that is known on `liquidityCommitmentClassifier.beforeAddLiquidity` context is:

```solidity
contract LiquidityCommitmentClassifier{
    function beforeAddLiquidity(
        address sender, // Liquiid
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData    
    )

    {
    
        if (!(existingTimeCommitment.isJIT) && !(enteredTimeCommitment.isJIT)) {
        // TODO: It needs to adjust the position accordingly
        // NOTE: Since the approach to be taken is liquidity to be stored
        // in the positionManager and managed by ERC-6909 claims
        // we need a "ClaimsManager" instead of "VaultManager",
        // And the claim tokens are the ones stored on "Vaults", in this case
        // PLP vaults, to earn passive income...
        }
        // ---> If the existing position is JIT and the request is JIT it only add more funds to the vaults
        // ==============================JIT -> JIT ===============================================
        if (existingTimeCommitment.isJIT && enteredTimeCommitment.isJIT) {
        // TODO: It only add more funds to the vaults
        // NOTE: In this case the "ClaimsManager" does not route the funds
        // to "PLPVaults" but to "JITClaim" manager that has a reference ta JITHook
        // This hook selects the orders where to apply JIT liquidity
        }
    }
}
```

## Type Definition

- One thing wee need to do is to define wheter is better to implement `LiquidityTimeCommitmentManager` as a contract or as a library.

> NOTE: At first glance it seems like a contract because it needs to have a service or interaction with the `TaxSystem` and `FeeRevenueManager` to apply taxes to JIT's and re-distribute them to PLP's based the `TaxSystem` logic.

- From now suppose it is a contract based on our initial intuition:



## Assumptions

- As it is seen on the [Introduction](#Introduction) the `LiquidityTimeCommitmentManager` already knows all the information from the LP request, whether is PLP, JIT and whether it's liquidity request is valid or not, thus we can work on the assumption that this is known and the  `LiquidityTimeCommitmentManager`.

## Services

- The main requirement of the `LiquidityTimeCommitmentManager` is to **manage** the liquidity that is _stored_ on the `PoolManager`.

- **When liquidity is added:**
  - Creates negative deltas (tokens `lp` needs to provide) to the respective `JIT/PLPLiquidityOperator`

- Query the __trading fee revenue__ generated for each trade satisfied by the `JIT/PLPLiquidityOperator`

- Enable the ability to allowed external entitites to modify the __trading fee revenue__
   
- **When liquidity is removed:**
 
  - Creates positive deltas (tokens `lp` receives) to the respective `JIT/PLPLiquidityOperator`

From here it follows:

* [function refinement tree](./functionRefinementTree.json)

> NOTE: This is done through the mechanism that `PoolManager` enables to manage it's funds by third parties, through `ERC6909` _claims_.



 

### `JITLiquidityTimeCommitmentManager`

### Services

- Enable the incorporation of (compatible ..,_more on compatibility later_ )`JITHooks`
- Allow the management of **funds** on vaults by the `JITHooks`


### `PLPLiquidityTimeCommitmentManager`




