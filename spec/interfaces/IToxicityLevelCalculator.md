# IToxicityLevelCalculator

This interface is a placeholder for a contract that would be responsible for calculating the toxicity level of a swap. This could be used to inform the JIT liquidity decisions made by the `JITHub`.

A future implementation of this interface could involve:

-   **On-chain analysis:** Analyzing patterns of recent trades to identify behavior typical of informed traders.
-   **Off-chain oracles:** Integrating with external data sources to assess the real-time risk of a swap.

The toxicity level would then be a key input for the `JITHub`'s `calculateJITLiquidityParamsForSwap` function, allowing for more nuanced and risk-aware JIT liquidity provision.
