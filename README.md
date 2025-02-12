# Insomnia Multi-Utility NFT

## Overview

**Insomnia Multi-Utility NFT** is a Solidity-based smart contract project designed to implement a multi-utility NFT system. The project leverages the **Foundry** framework for development, testing, and deployment.

## Features



## Installation

Ensure you have Foundry installed before proceeding:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Clone the repository and install dependencies:

```bash
git clone https://github.com/miquelcabot/insomnia-multi-utility-nft.git
cd insomnia-multi-utility-nft
forge install
```

## Usage

### Compilation

Compile the smart contracts:

```bash
forge build
```

### Running tests

Execute the test suite using Foundry:

```bash
forge test
```

You can also run the tests with coverage. The project is designed to achieve **100% line coverage**, ensuring all code paths are tested:

```bash
forge coverage
```

## Contract Design and Testing Approach

The **Insomnia Multi-Utility NFT** contract is designed with a focus on modularity, security, and efficiency. Below are the core design principles and testing methodologies employed:

### Phased Minting & Payment System

- Implements a **three-phase minting process** with Merkle proof verification:
  - **Phase 1:** Whitelisted users can mint for free.
  - **Phase 2:** Selected users mint at a discounted price, requiring a valid signature.
  - **Phase 3:** Open minting at full price for all users.
- Uses an **ERC20 token** as the primary payment method to handle transactions securely.

### Security Considerations

- Prevents **signature malleability** and replay attacks using **EIP-712 structured data signing**.
- Ensures **reentrancy protection** using best practices.
- Validates **Merkle proofs** to prevent unauthorized mints.
- All minting functions emit **events** for transparency and on-chain traceability.

### Vesting Mechanism

- Implements a **linear vesting schedule** via **Sablier**
- Only the contract owner can withdraw vested funds, providing controlled fund management.

### Gas Optimization Strategies

- Utilizes **efficient storage layouts** and avoids unnecessary state changes to minimize gas costs.
- Leverages **OpenZeppelin’s audited contracts**, ensuring robust ERC721 and ERC20 implementations.
- Applies **unchecked arithmetic** where safe to reduce unnecessary gas overhead.

### Testing Strategy

- **100% test coverage** is achieved by employing the **Branching Tree Technique (BTT)**.
- **Unit tests** validate individual contract components, ensuring correctness.
- **Integration tests** verify interactions between minting, payments, and vesting logic.

### Solidity & External Libraries

- The contract is built using **Solidity 0.8.26**, ensuring overflow protection without requiring additional SafeMath libraries.
- **Tagged releases** of OpenZeppelin libraries are used for stability and security.
- Security analysis is enhanced through **Slither** and other auditing tools.

By following these principles, the **Insomnia Multi-Utility NFT** contract ensures security, efficiency, and a seamless user experience. 🚀
