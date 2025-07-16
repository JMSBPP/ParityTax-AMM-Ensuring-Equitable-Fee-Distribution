# Function Refinement Tree

This document breaks down the high-level functions of the ParityTax system into more detailed sub-functions and the services they rely on.

---

## JIT Liquidity Taxation

**Description:** Enforce taxes on JIT liquidity providers during swaps via hook logic.

**Services:**
- `UniswapV4 Hooks`

### Sub-functions

-   **Calculate JIT Tax**
    -   **Description:** Compute tax rate based on position duration, trade size, and market impact.

-   **Apply Tax in Swap Hooks**
    -   **Description:** Deduct tax during `beforeSwap`/`afterSwap` and allocate to the redistribution pool.
    -   **Services:**
        -   `Hook.beforeSwap`
        -   `Hook.afterSwap`
        -   `Hook.afterSwapReturnDelta`

---

## PLP Reward Redistribution

**Description:** Distribute taxed JIT revenue to passive LPs post-removal.

**Services:**
- `UniswapV4 Hooks`

### Sub-functions

-   **Track PLP Contributions**
    -   **Description:** Record liquidity depth and duration for each PLP position.
    -   **Services:**
        -   `PoolManager.liquidityLedger`

-   **Redistribute on Removal**
    -   **Description:** Allocate rewards proportionally in the `afterRemoveLiquidity` hook.
    -   **Services:**
        -   `Hook.afterRemoveLiquidity`
    -   **Sub-functions:**
        -   **Calculate PLP Shares**
            -   **Description:** Weight rewards by `(liquidity × duration) / totalEligibleLiquidity`.

---

## Time-Locked Liquidity Manager

**Description:** Enforce deadlines for JIT liquidity positions.

**Services:**
- `UniswapV4 Hooks`

### Sub-functions

-   **Validate Position Expiry**
    -   **Description:** Check if `block.timestamp` exceeds the LP-specified deadline.
    -   **Services:**
        -   `Hook.beforeModifyPosition`

-   **Expire JIT Positions**
    -   **Description:** Automatically remove liquidity if the deadline has passed.
    -   **Services:**
        -   `PoolManager.removeLiquidity`

---

## Dynamic Incentive Calibration

**Description:** Adjust tax/redistribution parameters in real-time.

**Services:**
- `UniswapV4 Hooks`

### Sub-functions

-   **Monitor JIT/PLP Ratios**
    -   **Description:** Track liquidity participation metrics on-chain.
    -   **Services:**
        -   `PoolManager.liquiditySnapshot`

-   **Update Tax Parameters**
    -   **Description:** Modify rates via governance or algorithmic feedback.
    -   **Services:**
        -   `GovernanceModule`
    -   **Sub-functions:**
        -   **Apply Control Theory**
            -   **Description:** Use a PID controller to stabilize the JIT/PLP equilibrium.
