# LiquidityOperators Registry


```solidity
mapping(address liquidityProvider => LPTimeCommitment) private lpTimeCommitments;

```

- The `liquidityProvider` key is passed by the `LPTypeLiquidityRouter`

```solidity
//NOTE: This fucntion is callled only by the router

function setLPTimeCommitment(
   address liquidityProvider
   LPTimeCommitment lpTypeTimeCommitment
) external 
```