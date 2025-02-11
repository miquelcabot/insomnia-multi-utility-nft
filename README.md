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

## Contract Design and Testing Approach

The contract design follows modular principles to ensure maintainability and scalability. The `MultiUtilityNFT` contract extends ERC721 while integrating additional functionalities such as mint operations and lockup mechanisms.

The testing strategy includes:

- **Unit Tests**: Validate individual contract components.
- **Integration Tests**: Ensure interactions between different contract modules function correctly.
- **Fuzz Testing**: Randomized inputs to test edge cases and unexpected behaviors.
