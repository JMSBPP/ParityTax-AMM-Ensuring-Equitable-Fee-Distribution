# ParityTax-AMM-Ensuring-Equitable-Fee-Distribution
<p align="center">
  <img src="assets/logo.png" alt="Description" width="300"/>
</p>

- Let us consider 3 traders $A, B,C$ relying on the AMM $M$ to trade with only two liquidity providers $D,E$

## Model Assumptions:


### Traders
- $A$ is a non-informed trader.
- $B$ is a back-arb trader
- $C$ is an informed trader
- There exist a liquidity perfect market $\star$ where:

- $C$ tracks for the purpose of performing his informed trading trades responding to deviations on $\star$ to be applied on $M$.

- $B$ tracks with the prupose of responding to $A$ trades that result on price deviations to be corrected on $M$


### Liquidity Providers

- $D$ is a JIT LP which only captures orders of $A,B$
- $E$ is a PLP which only captures orders of $C$

## Model Set-Up:

- The initial conditions are as follows:
- We define a time frame $t_0$ to $t_N$ where actions will take place:

- We now endorse each agent of the system with equal amount of capital of each token at $t_0$:
- At time $t_0$ the $E$ deposits all its capital on the AMM to provide liquidity.
- Then we define the process on which $A$ trades will take place exclussively on the AMM.
- At first we will assume that $E$ never withdraws liquidity, therefore the liquidity depth remains constant and known to trades at all times.
- Knowing this $A$ will trade such that the underlying AMM price process follows a brownian motion with mean price defined throughout the whole $t_N$, we will suppose that they will trade on eahc $t_i$
- The external market $\star$ will follow a drifted stochastic process for its underlying price.
- Then the following will happen:
- For all $t_i$ where the prices deviate from $\star$ to $M$ $B$ will trade maximizing its payoff function. Then $B$ only responds to price shifts from $\star \to M$
- Conversely $C$ responds to price shifts from $M \to \star$ maximizing its payoff function.
- Finally $D$ will only fullill $A, C$ orders leaving all $B$ orders to be fulfilled by the $E$


## Workflow:

- Define cadCad variables, parameters, policies
- Run Simulation
- Run Simulation on a forked enviroment 
- Get data and contrast simulation reslts with empirical results
- Define the system to be followed on Solidity

## State Variables

- At first we need to define the process that the external (__primary__) market will follow, This is define a Brownian Motion, that:
$$
P^\star_{Y/X} = f \bigg (\mathcal{L}^O_{\star}, \mathcal{L}^D_{B-ARB}, \mathcal{L}^D_{I} \bigg )
$$ 

Where:
$$
\begin{align*}
  \mathcal{L}^O_{\star}:= \, \, \text{External Market Liquidity Depth} \\
  \\
  \mathcal{L}^D_{B-ARB}:= \, \, \text{Back-Arbitrageur External Market Liquidity Demand} \\
  \\
  \mathcal{L}^D_{I} := \, \text{Informed Trader External Market Liquidity Demand}
\end{align*}
$$

We can then construct the model:

$$
P^\star_{Y/X} = \beta_0 + \beta_1 \cdot \mathcal{L}^D_{B-ARB} + \beta_2\cdot \mathcal{L}^D_{I} + \varepsilon \\
$$


