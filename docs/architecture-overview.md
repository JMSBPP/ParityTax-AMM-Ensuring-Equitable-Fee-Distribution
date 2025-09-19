# ParityTax-AMM Architecture Overview

## System Overview and Goals

The **ParityTax-AMM** is a sophisticated DeFi protocol built on Uniswap V4 that implements an equitable fee distribution mechanism between Just-In-Time (JIT) and Passive Liquidity Providers (PLP). The system addresses critical inefficiencies in current AMM market structures by creating a balanced liquidity ecosystem that prevents predatory behavior and ensures fair fee distribution.

### Core Problem Statement
Current AMM market structures suffer from:
- **Reduced Trading Incentives**: 
Traders hesitate when passive liquidity is insufficient or JIT provision is uncertain

- **Excessive Price Impact**: Large orders suffer significant slippage when JIT liquidity is scarce
- **Vulnerability to Predatory Behavior**: Absence of robust PLP exposes traders to opportunistic JIT strategies

### Solution Philosophy
The ParityTax-AMM creates a balanced ecosystem where:
- **PLP acts as dependable baseline**: Reduces volatility and slippage
- **JIT complements rather than dominates**: Prevents exploitative practices
- **Traders execute with confidence**: Fair pricing and minimal adverse selection

## Key Architectural Decisions

### 1. Uniswap V4 Hook Integration
- **Decision**: Built as a Uniswap V4 hook system rather than a standalone AMM
- **Rationale**: Leverages Uniswap's battle-tested infrastructure while adding custom fee distribution logic
- **Implementation**: Implements all required hook interfaces (`beforeSwap`, `afterSwap`, `beforeAddLiquidity`, `afterAddLiquidity`, etc.)

### 2. Dual Liquidity Provider System
- **Decision**: Distinguish between JIT and PLP with different commitment requirements
- **Rationale**: Enables differentiated fee distribution based on commitment levels
- **Implementation**: 
  - JIT: `JIT_COMMITMENT = 1` (immediate liquidity)
  - PLP: `MIN_PLP_BLOCK_NUMBER_COMMITMENT = 2` (minimum 2-block commitment for passive liquidity)

### 3. Reactive Network Integration
- **Decision**: Use reactive network for real-time fiscal policy updates
- **Rationale**: Enables dynamic tax rate adjustments based on market conditions
- **Implementation**: `FiscalListeningPost` contract forwards events to fiscal policy

### 4. Transient Storage Optimization
- **Decision**: Use OpenZeppelin's transient storage for temporary data
- **Rationale**: Gas-efficient storage for data that only needs to persist during transaction execution
- **Implementation**: Custom storage locations for JIT/PLP positions and price impact data

## Component Relationships

### Core Components

#### 1. ParityTaxHook
- **Role**: Main hook contract implementing Uniswap V4 hook system
- **Key Functions**:
  - `_beforeSwap()`: Handles JIT liquidity addition and price tracking
  - `_afterSwap()`: Processes JIT liquidity removal and fee collection
  - `_beforeAddLiquidity()`: Manages liquidity addition with commitment validation
  - `_afterAddLiquidity()`: Handles post-liquidity addition fee collection
  - `_beforeRemoveLiquidity()`: Validates liquidity removal permissions
  - `_afterRemoveLiquidity()`: Processes fee calculations for liquidity removal

#### 2. ParityTaxRouter
- **Role**: Router contract for executing swaps and liquidity operations
- **Key Functions**:
  - `swap()`: Executes swaps with hook integration and price impact simulation
  - `modifyLiquidity()`: Handles liquidity modifications with PLP commitment handling
  - `unlockCallback()`: Entry point for pool manager callbacks

#### 3. FiscalListeningPost
- **Role**: Reactive network bridge for forwarding events to fiscal policy
- **Key Functions**:
  - `react()`: Processes incoming log records and forwards to fiscal policy
  - Event forwarding for `PriceImpact`, `LiquidityOnSwap`, `LiquidityCommitted`, and `Remittance`

#### 4. Supporting Contracts
- **LiquidityMetrics**: Tracks liquidity-related metrics and analytics
- **SwapMetrics**: Monitors swap performance and price impact
- **LiquiditySubscriptions**: Manages liquidity provider subscriptions

### Data Flow Architecture

#### Swap Execution Flow
1. **User initiates swap** → `ParityTaxRouter.swap()`
2. **Price simulation** → Calculate expected price impact
3. **Hook data preparation** → Create `SwapContext` with swap parameters
4. **Pool manager callback** → `ParityTaxHook._beforeSwap()`
5. **JIT liquidity addition** → Add JIT liquidity through resolver
6. **Swap execution** → Uniswap V4 core swap logic
7. **Post-swap processing** → `ParityTaxHook._afterSwap()`
8. **JIT liquidity removal** → Remove JIT liquidity and collect fees
9. **Fee remittance** → Send fees to fiscal policy

#### Liquidity Addition Flow
1. **User initiates liquidity addition** → `ParityTaxRouter.modifyLiquidity()`
2. **Commitment validation** → Check PLP commitment requirements
3. **Hook data preparation** → Create `Commitment` struct
4. **Pool manager callback** → `ParityTaxHook._beforeAddLiquidity()`
5. **Liquidity commitment** → Lock liquidity with block commitment
6. **Liquidity addition** → Uniswap V4 core liquidity logic
7. **Post-addition processing** → `ParityTaxHook._afterAddLiquidity()`
8. **Fee collection** → Process and remit fees to fiscal policy

## Technology Stack Overview

### Core Dependencies

#### Uniswap V4 Integration
- **v4-core**: Core AMM functionality and hook system
- **v4-periphery**: Position management and quoter functionality
- **Purpose**: Provides the foundational AMM infrastructure

#### Security and Utilities
- **OpenZeppelin Contracts**: Security patterns and access control
- **Solady**: Gas-optimized utility functions
- **Forge Std**: Testing utilities and cheatcodes

#### Specialized Dependencies
- **Balancer v3**: Multi-asset pool patterns (reference)
- **Euler**: Lending integration patterns (reference)
- **Jitterbug**: MEV protection strategies (reference)

### Data Structures

#### Core Types
- **`FeeRevenueInfo`**: Packed structure for efficient fee tracking
- **`SwapContext`**: Comprehensive swap state information
- **`LiquidityPosition`**: Complete liquidity position data
- **`Commitment`**: Block number commitment for liquidity providers

#### Transient Storage
- **JIT Position Data**: `JIT_LIQUIDITY_POSITION_LOCATION`
- **PLP Position Data**: `PLP_LIQUIDITY_POSITION_LOCATION`
- **Price Impact Data**: `PRICE_IMPACT_LOCATION`
- **Tax Rate Data**: `TAX_RATE_SLOT`

## System Integration Points

### External Integrations

#### 1. Uniswap V4 Pool Manager
- **Interface**: `IPoolManager`
- **Purpose**: Core AMM operations (swap, modifyLiquidity, donate)
- **Integration**: Direct hook implementation

#### 2. Position Manager
- **Interface**: `IPositionManager`
- **Purpose**: NFT-based position management
- **Integration**: Position creation and management for liquidity providers

#### 3. LP Oracle
- **Interface**: `ILPOracle`
- **Purpose**: Liquidity price information
- **Integration**: Price data for fee calculations

#### 4. Fiscal Policy
- **Interface**: `IFiscalPolicy`
- **Purpose**: Tax rate calculations and fee distribution
- **Integration**: Reactive network event forwarding

### Internal Interfaces

#### 1. JIT Resolver
- **Interface**: `IJITResolver`
- **Purpose**: Just-In-Time liquidity management
- **Integration**: Dynamic liquidity addition/removal

#### 2. PLP Resolver
- **Interface**: `IPLPResolver`
- **Purpose**: Passive Liquidity Provider management
- **Integration**: Passive liquidity commitment handling

## Security Architecture

### Access Control
- **Position Manager Only**: Liquidity operations restricted to position manager
- **Pool Manager Only**: Callback functions restricted to pool manager
- **Reactive Network Only**: Event processing restricted to reactive network

### Transient Storage Security
- **Isolated Storage**: Each data type uses unique storage locations
- **Transaction Scoped**: Data automatically cleared after transaction
- **Gas Efficient**: Reduces storage costs for temporary data

### Commitment Validation
- **PLP Minimum Commitment**: Enforces minimum 2-block commitment
- **JIT Immediate Processing**: Allows immediate liquidity operations
- **Block Number Validation**: Prevents premature liquidity removal

## Performance Optimizations

### Gas Efficiency
- **Packed Data Structures**: `FeeRevenueInfo` uses bit packing
- **Transient Storage**: Reduces storage costs for temporary data
- **Assembly Operations**: Bit manipulation for optimal gas usage

### Memory Management
- **Library Usage**: Extensive use of libraries for code reuse
- **Struct Packing**: Optimized struct layouts for gas efficiency
- **Callback Optimization**: Efficient callback data structures

## Future Evolution Plans

### Phase 1: Core Implementation
- Complete hook system implementation
- Basic fee distribution mechanism
- JIT/PLP differentiation

### Phase 2: Advanced Features
- Dynamic tax rate adjustments
- MEV protection integration
- Advanced analytics and metrics

### Phase 3: Ecosystem Expansion
- Multi-chain deployment
- Cross-chain liquidity management
- Advanced governance mechanisms

## Design Patterns Used

### 1. Hook Pattern
- **Implementation**: Uniswap V4 hook system
- **Purpose**: Extend core AMM functionality without modification

### 2. Reactive Pattern
- **Implementation**: Reactive network integration
- **Purpose**: Real-time response to market events

### 3. Factory Pattern
- **Implementation**: Resolver contracts for JIT/PLP management
- **Purpose**: Standardized liquidity provider management

### 4. Observer Pattern
- **Implementation**: Event forwarding to fiscal policy
- **Purpose**: Decoupled event processing and tax calculations

## Conclusion

The ParityTax-AMM represents a sophisticated approach to solving AMM inefficiencies through careful architectural design. By leveraging Uniswap V4's hook system, implementing dual liquidity provider types, and integrating with reactive networks, the system creates a balanced ecosystem that promotes fair fee distribution while maintaining the efficiency and security of the underlying AMM infrastructure.

The architecture's modular design allows for future enhancements while maintaining backward compatibility, and the extensive use of gas optimizations ensures the system remains cost-effective for users. The integration of reactive networks enables dynamic policy adjustments, making the system adaptable to changing market conditions.

---

*Last Updated: [Current Date]*
*Version: 1.0*
*Maintainer: Architecture Team*
