# ToxicityLevel

The `ToxicityLevel` type is a custom data type, represented as a `uint8`, intended to classify the "toxicity" of a swap.

## Purpose

In the context of liquidity provision, a "toxic" swap is typically one initiated by an informed trader who has knowledge that the current market price is incorrect. Providing liquidity to such a trade is risky and often results in losses for the liquidity provider (adverse selection).

The `ToxicityLevel` is designed to be a quantitative measure of this risk. While the current implementation is a placeholder, a future version could incorporate on-chain and off-chain data to calculate a toxicity score for each swap. This score would then be used by the `JITHub` to make more sophisticated decisions about when and how to provide JIT liquidity, potentially avoiding highly toxic trades.