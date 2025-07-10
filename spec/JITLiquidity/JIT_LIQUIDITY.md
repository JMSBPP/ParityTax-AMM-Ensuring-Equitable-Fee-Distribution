## Results:
- Uniswap v3 supported over $\$600 \, \text{bn}$ of trading
volume in the same period, meaning that JIT liquidity filled $0.3\%$ of all liquidity
demand.

- JIT liquidity has historically been concentrated
across the top pools on Uniswap by trading volume --> __This outlies the issue that JIT improving price quality is limited to stable pools__. (__The top ten pools account for 95%. On the demand side, the top 10 pools account for just 55% of
total trading volume.__)

- **JIT transactions are only profitable
when the swap in the middle is large enough, and large trades are much more
concentrated in the top pools**


### Questions
- How to incentivize JIT on volatile pools?
  - **Hint:**  pairs in large
pools have greater liquidity on centralized exchange venues, making the hedging
transaction much easier and cheaper to complete. $\to$ Create alternative relaibale hedging mechanism for volatile pools.


## Advantages:

## `beforeSwap`

- Calculate revenue:
$$
Y^{LP} \bigg ( \phi^M, \Delta \big (\big [ i_{k}, i_{k+\varepsilon}\big ]\big ) \bigg) = \mathcal{L} \bigg ( \big [ i_{k}, i_{k+\varepsilon}\big ] \bigg) \cdot \phi \bigg ( \Delta \big (\big [ i_{k}, i_{k+\varepsilon}\big ]\big) \bigg) + \mathcal{p} \bigg ( P_{Y/X} \big ( \Delta \big ), P_{Y/X} \big (0\big)\bigg)
$$