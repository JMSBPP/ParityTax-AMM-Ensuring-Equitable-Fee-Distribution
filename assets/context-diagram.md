# ParityTax-AMM Context Diagram

```mermaid
graph TB
    %% System Under Development (Center)
    SuD[ParityTax-AMM System<br/>Equitable Fee Distribution]
    
    %% Infrastructure Entities (Top)
    Uniswap[Uniswap v4 Core Protocol<br/>AMM Infrastructure]
    Reactive[Reactive Network<br/>Event Processing]
    Oracle[Oracle Services<br/>Price Data]
    
    %% Market Participants (Left)
    JIT[JIT Liquidity Providers<br/>Just-in-Time LPs]
    PLP[PLP Liquidity Providers<br/>Passive LPs]
    Traders[Traders<br/>Market Participants]
    
    %% Administrative Entities (Right)
    Deployers[Pool Deployers<br/>System Administrators]
    Governance[Governance Token Holders<br/>Stakeholders]
    
    %% Service Contracts (Bottom)
    Fiscal[Fiscal Policy Implementations<br/>Custom Taxation Logic]
    Resolvers[External Resolvers<br/>JIT/PLP Identification]
    
    %% Causal Communication (Bold arrows - direct actions)
    JIT -->|"Fee Payment & Taxation"| SuD
    PLP -->|"Liquidity Commitment & Rewards"| SuD
    Deployers -->|"Policy Configuration"| SuD
    SuD -->|"Function Calls & Data Updates"| Fiscal
    SuD -->|"Event Publishing & State Changes"| Reactive
    
    %% Informational Communication (Dashed arrows - data exchange)
    Uniswap -.->|"Pool State & Market Data"| SuD
    Traders -.->|"Trading Patterns & Price Impact"| SuD
    Oracle -.->|"External Price & Market Data"| SuD
    Resolvers -.->|"LP Type Identification"| SuD
    SuD -.->|"Governance Proposals & Metrics"| Governance
    SuD -.->|"Performance Metrics & Recommendations"| Deployers
    
    %% Styling
    classDef system fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef infrastructure fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef participants fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef admin fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef services fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    
    class SuD system
    class Uniswap,Reactive,Oracle infrastructure
    class JIT,PLP,Traders participants
    class Deployers,Governance admin
    class Fiscal,Resolvers services
```

## Legend

- **Bold Arrows**: Causal communication (direct actions affecting the system)
- **Dashed Arrows**: Informational communication (data exchange for decision making)
- **System Under Development**: ParityTax-AMM System (center)
- **External Entities**: All other components that interact with the system

## Communication Types

### Causal Communication
- JIT LPs → SuD: Fee payment and taxation
- PLPs → SuD: Liquidity commitment and reward claims
- Pool Deployers → SuD: Policy parameter configuration
- SuD → Fiscal Policy: Function calls and data updates
- SuD → Reactive Network: Event publishing and state changes

### Informational Communication
- Uniswap v4 → SuD: Pool state and market data
- Traders → SuD: Trading patterns and price impact data
- Oracle Services → SuD: External price and market data
- External Resolvers → SuD: LP type identification data
- SuD → Governance: Governance proposals and metrics
- SuD → Pool Deployers: Performance metrics and recommendations
