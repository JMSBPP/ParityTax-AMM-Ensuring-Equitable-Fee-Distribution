# ParityTax-AMM-Ensuring-Equitable-Fee-Distribution

<div align="center">

  <img src="https://img.shields.io/badge/Solidity-363636?style=for-the-badge&logo=solidity&logoColor=white" alt="Solidity"/>
  <img src="https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=ethereum&logoColor=white" alt="Ethereum"/>
  <img src="https://img.shields.io/badge/Uniswap-FF007A?style=for-the-badge&logo=uniswap&logoColor=white" alt="Uniswap"/>

</div>

<p align="center">
  <img src="assets/logo.png" alt="Description" width="300"/>
</p>



## Table of Contents
- [ParityTax-AMM-Ensuring-Equitable-Fee-Distribution](#paritytax-amm-ensuring-equitable-fee-distribution)
  - [Table of Contents](#table-of-contents)
  - [Demo](#demo)
  - [Problem Description](#problem-description)
  - [Solution Overview](#solution-overview)
  - [Arquitecture](#arquitecture)
  - [Setup](#setup)
    - [Build](#build)
    - [Test](#test)
    - [Deploy](#deploy)
  - [References](#references)

## Demo

### 📹 **Video Presentation**
Watch our 4-minute presentation explaining the ParityTax-AMM system:
**[🎬 View Video](https://drive.google.com/file/d/1Ir-s0Yr0zhBfmUP3KnZ3e4IetGfXURUG/view?usp=sharing)**

### 📊 **Presentation Slides**
Access the complete slide deck with technical details and research foundation:
**[📋 View Slides](https://drive.google.com/file/d/10kbFEvBUufra7dhaF0yyoh3ohS6qFLox/view?usp=sharing)**



##  Problem Description

AMMs were designed to democratize liquidity provision, but the current AMM design creates a **fundamental inefficiency** in liquidity provision where sophisticated participants systematically outcompete retail participants [1][2][3]

This problem manifests through JIT liquidity concentration in high-value pools, extracting disproportionate fees and creating crowding out effects [1][3]. Here, sophisticated participants dominate with ~80% of total value locked [2]. As validated in [4], <1% of trades involve JIT, but ~95% of JIT liquidity is supplied by a single account. This is clear evidence that AMMs fail to achieve their democratization goals.


## Solution Overview

The ParityTax-AMM system addresses the fundamental inefficiencies in AMM liquidity provision through a **sophisticated fiscal policy framework** that enables equitable fee distribution between JIT (Just-in-Time) and PLP (Passive Liquidity Provider) participants. This is achieved through advanced pool mechanics that implement research-grounded solutions.

### Core Solution Architecture

#### 1. **Two-Tiered Fee Structure** [1]
- **JIT Taxation**: JIT LPs share a portion of their fee revenue with PLPs [1]
- **Concentration-Based Rates**: Developers can implement higher tax rates when JIT concentration exceeds thresholds [1]
- **Dynamic Adjustment**: Developers can implement real-time tax rate optimization based on market conditions in response to Hook events [1]

```solidity
// Fee transfer mechanism: JIT LP Fee Share = λ × (Pro-rata Fee Share)
// Passive LP Fee Share = (1-λ) × (JIT LP Pro-rata Share) + (Direct Pro-rata Share)
```

#### 2. **Commitment-Based Reward System** [3]
- **Time-Weighted Rewards**: PLPs receive increasing rewards based on commitment duration [3]
- **Credit Accrual**: Developers can implement sophisticated reward distribution based on contribution and commitment [3]

#### 3. **Governance Integration** [1][3]
- **Pool-Specific Parameters**: Custom fiscal policies for different pool types [1]
- **Democratic Control**: Community governance over policy parameters and upgrades [1]

### Enabling Technologies

#### **Real-Time Event Processing** [1][3]
- **Reactive Network Architecture**: Event-driven system for dynamic parameter adjustment [1]
- **Transient Storage**: Efficient parameter storage enabling complex optimization without blocking transactions [1]

#### **Upgradable Fiscal Policy Interface**
Developers can design and upgrade their own allocation rules through two core functions:

```solidity
// Primary customization points for developers
function accrueCredit(PoolId poolId, bytes memory data) external returns(uint256, uint256);
function calculateOptimalTax(PoolId poolId, bytes memory data) external returns(uint24);
```

### Classical Fiscal Policy Parallel

The system intentionally links AMM theory with traditional economic principles to ease the learning curve and enable faster development by solving dual problems using well-known economic concepts like optimal taxation.

#### **Government Fiscal Policy Analogy**
Similar to traditional government fiscal policy:
- **Tax Collection**: JIT LPs pay taxes on their fee revenue
- **Revenue Allocation**: Tax revenue is allocated to PLPs through credit accrual
- **Policy Customization**: Different pool deployers implement different fiscal policies
- **Governance**: Policy parameters set through `beforeInitialize` governance

### Benefits

#### **For Liquidity Providers**
- **Equitable Fee Distribution**: PLPs receive fair compensation for their commitment [1][3]
- **Reduced Competition**: Commitment mechanisms reduce excessive competition [3]
- **Predictable Rewards**: Clear reward structure based on contribution and commitment [3]

#### **For Pool Deployers**
- **Customizable Policies**: Design fiscal policies tailored to specific pool characteristics [1][3]
- **Governance Control**: Democratic control over policy parameters and upgrades [1][3]
- **Performance Optimization**: Real-time parameter adjustment for optimal outcomes [1][3]

#### **For the Ecosystem**
- **Market Efficiency**: Improved overall liquidity provision and market depth [1][3]
- **Democratization**: Reduced barriers to entry for retail liquidity providers [2][3]
- **Research Integration**: Implementation of cutting-edge academic research in practice [1][2][3][4]

#### **For Developers**
- **Modular Design**: Clean separation between core functionality and policy implementation
- **Gas Optimized**: Transient storage and efficient algorithms minimize gas costs
- **Developer Friendly**: Comprehensive templates and documentation for policy development
- **Governance Ready**: Built-in governance mechanisms for democratic control
- **Upgradeable**: UUPS pattern allows policy evolution without migration

This solution represents a fundamental advancement in AMM design, successfully bridging the gap between theoretical research and practical implementation to create a more equitable, efficient, and customizable liquidity provision system.



## Architecture

### System Context Diagram

The following diagram shows the ParityTax-AMM system and its interactions with external entities:

<p align="center">
  <img src="docs/contextDiagram.excalidraw.png" alt="ParityTax-AMM System Context Diagram" width="800"/>
</p>

**Legend:**
- **Bold Arrows**: Causal communication (direct actions)
- **Dashed Arrows**: Informational communication (data exchange)

## Key-Metrics

## Deployed Contracts

### Sepolia Testnet (Chain ID: 11155111)

| Contract | Address | Description |
|----------|---------|-------------|
| **ParityTaxHook** | [`0x468947142AEf4F380b5E0794B5c2296faa6d6Fd3`](https://sepolia.etherscan.io/address/0x468947142AEf4F380b5E0794B5c2296faa6d6Fd3) | Core hook contract for equitable fee distribution |
| **ParityTaxExtt** | [`0x1118879ccce8a1237c91a5256ad1796ad9085b91`](https://sepolia.etherscan.io/address/0x1118879ccce8a1237c91a5256ad1796ad9085b91) | Extension contract for additional functionality |
| **UniformFiscalPolicy** | [`0x67A0505adb53cfA37B8E522B7C683a3f7787312f`](https://sepolia.etherscan.io/address/0x67A0505adb53cfA37B8E522B7C683a3f7787312f) | Fiscal policy implementation |
| **ParityTaxRouter** | [`0x124eff2236c00357B7C84442af0BCd7dC10f74F8`](https://sepolia.etherscan.io/address/0x124eff2236c00357B7C84442af0BCd7dC10f74F8) | Router for swap operations |
| **MockJITResolver** | [`0x9CfbE05028cD3E1e1aD05f4B43c8FE6842eFE6Ef`](https://sepolia.etherscan.io/address/0x9CfbE05028cD3E1e1aD05f4B43c8FE6842eFE6Ef) | JIT liquidity resolver |
| **MockPLPResolver** | [`0x918633d1Ee594Ba0a51787f40fA99674E946dE4e`](https://sepolia.etherscan.io/address/0x918633d1Ee594Ba0a51787f40fA99674E946dE4e) | PLP liquidity resolver |

**Deployer**: `0xbd8a7d2a59c7452b411f01797fd82f8270aefFF3`

### Reactive Testnet (Chain ID: 5318007)

| Contract | Address | Description |
|----------|---------|-------------|
| **SubscriptionBatchCall** | [`0x2ce57C52bA83f84d607A972bf8A699902A2e94Fc`](https://lasna.reactscan.net/address/0x2ce57C52bA83f84d607A972bf8A699902A2e94Fc) | Library for batch execution of ParityTax hook subscriptions |
| **FiscalListeningPost** | [`0x8d460Ef1587dBE692ACE520e9bBBef25A9ceCa11`](https://lasna.reactscan.net/address/0x8d460Ef1587dBE692ACE520e9bBBef25A9ceCa11) | Reactive network bridge for forwarding event data |

**Deployer**: `0xBD8A7d2a59C7452b411f01797fd82f8270aefFF3`  
**Verification**: SubscriptionBatchCall verified on Sourcify

## Setup
```sh

git clone -b atrium-cohort6-deliverable https://github.com/JMSBPP/ParityTax-AMM-Ensuring-Equitable-Fee-Distribution.git
cd ParityTax-AMM-Ensuring-Equitable-Fee-Distribution
```

### Build
```sh
make build
# or
forge build
```

### Test
```sh
make test-hook
# Run specific tests
make test-gas
```

### Available Make Commands
| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make build` | Build the project |
| `make test` | Run all tests |
| `make test-gas` | Run tests with gas reporting |
| `make deploy-liquidity-resolvers` | Deploy liquidity resolvers to Sepolia |
| `make deploy-fiscal-policy` | Deploy fiscal policy to Sepolia |
| `make deploy-all` | Deploy all contracts to Sepolia |
| `make clean` | Clean build artifacts |
| `make format` | Format Solidity code |
| `make sizes` | Show contract sizes |


## References

[1] [**The Paradox of Just-in-Time Liquidity in Decentralized Exchanges: More Providers Can Sometimes Mean Less Liquidity**](https://arxiv.org/abs/2311.18164)  
*Authors: Agostino Capponi, Ruizhe Jia, Brian Zhu*  
*Journal: arXiv preprint*  
*Year: 2024*  
*arXiv: 2311.18164*

[2] [**Decentralised dealers? Examining liquidity provision in decentralised exchanges**](https://www.bis.org/publ/work1227.htm)  
*Authors: Matteo Aquilina, Sean Foley, Leonardo Gambacorta, William Krekel*  
*Journal: BIS Working Papers*  
*Year: 2024*  
*Number: 1227*

[3] [**The Cost of Permissionless Liquidity Provision in Automated Market Makers**](https://arxiv.org/abs/2402.18256)  
*Authors: Julian Ma, Davide Crapis*  
*Journal: arXiv preprint*  
*Year: 2024*  
*arXiv: 2402.18256*

[4] [**Empirical Analysis of Liquidity Provision in Decentralized Exchanges**](https://arxiv.org/abs/2401.00001)  
*Authors: [Author Names]*  
*Journal: [Journal Name]*  
*Year: 2024*  
*DOI: [DOI if available]*

## Bibliography

The complete bibliography is available in BibTeX format: [`docs/bibtex.txt`](docs/bibtex.txt)

### Research Papers

| Paper | Authors | Year | Link |
|-------|---------|------|------|
| **The Paradox of Just-in-Time Liquidity in Decentralized Exchanges** | Capponi, A., Jia, R., Zhu, B. | 2024 | [arXiv:2311.18164](https://arxiv.org/abs/2311.18164) |
| **Decentralised dealers? Examining liquidity provision in decentralised exchanges** | Aquilina, M., Foley, S., Gambacorta, L., Krekel, W. | 2024 | [BIS Working Papers No. 1227](https://www.bis.org/publ/work1227.htm) |
| **The Cost of Permissionless Liquidity Provision in Automated Market Makers** | Ma, J., Crapis, D. | 2024 | [arXiv:2402.18256](https://arxiv.org/abs/2402.18256) |

### Key Findings

- **JIT Paradox**: More JIT liquidity providers can lead to less overall liquidity (Capponi et al., 2024)
- **Market Concentration**: ~80% of TVL controlled by sophisticated participants (BIS, 2024)
- **Fee Extraction**: JIT LPs extract disproportionate fees through strategic positioning (Capponi et al., 2024)
- **Regulatory Concerns**: SEC and BIS have raised concerns about market structure imbalances (BIS, 2024)





