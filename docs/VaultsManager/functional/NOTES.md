# `VaultsManager`

- They receive the following data from the `liquidityCommitmentManagerHook.beforeAddLiquidity`:


```solidity
struct CallbackData{
    address liquidityProvider,
    PoolKey key,
    ModifyLiquidityParams liquidityParams,
    TimeCommitment timeCommitment
}
```

- From here what they do is to `routeLiquidity` to `JITVault` or `PLPVault`.

dsds
```solidity
interface IVaultManager{
    function routeLiquidity(
        bytes memory encodedCallbackData
    )
    external 
    returns (ILPVault vaultManagerWhereLiquidityWasRoutedTo)
    {
        //1. Route the liquidity optimistically, this is becuase the liquidityManagerHook already verified that the liquidity request is compatible with the LP-type
    }

}

abstract contract VaultManager is IVaultManager, BaseHook{
    
    PLPVaults;
    JITVaults;

    function beforeSwap(
        address sender,
        PoolKey calldata key, 
        SwapParams calldata params,
        bytes calldata hookData
        )
        external
        onlyPoolManager
        returns (bytes4, BeforeSwapDelta, uint24){
            
            //1. It calls the JITVaults and presnet the swapReques
            
            //2. The JITVaults each has it's JIJTHook where each
            // figure out if they wnat to fullfill or not the trade
            
            // --> If fullfilled on afterSwap it queries the feesEarned
            // by the JIT's and store it accrdincly
            // --> If no one wnats to fullfill the trade then it is passed 
            // to egular swapping logic using PLP liquidity, where on afterSwap 
            // it also keep track of the revenue gained by PLP's

            //3. Finally it calls the taxSystem to determine the tax for this
            // trade applied to JIT's
            
            // 4. Tax is appplied and tax revenue is transfered to PLP's 
        }
}
abstract contract LPVault{
    using TaxMath for feesEarned;

    mapping(Vault[2] => feesEarned) private feesEarned;
}

abstract contract JITVaultManager is VaultManager{
    

    JITHook private jitHook;
    
    // Variables related to keep track of fees Transfered to PLP lP's
}

abstract contract PLPVaultManager is VaultManager{
    //Locking related state variables

    // Variables associated with other income sources for locked
    // funds

    // Variables related to keep track of fees Transfered from JIT lP's

}

```