# `VaultsManager`

```solidity
abstract contract VaultsManager{
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