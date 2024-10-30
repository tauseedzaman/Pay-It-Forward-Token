# Pay It Forward (PIF) Token

![PIF Token Logo](link-to-your-logo)

## Overview

The Pay It Forward (PIF) Token is an ERC20 token designed for the platform [thebenefactor.net](https://thebenefactor.net). This smart contract allows users to perform transactions with built-in buy/sell fees that are redistributed based on defined allocations for platform rewards and operating expenses. Utilizing OpenZeppelin libraries, it ensures security and reliability.

## Features

- **ERC20 Standard**: Complies with the ERC20 token standard for interoperability.
- **Pausable**: Allows the contract owner to pause all transfers in case of emergencies.
- **Buy/Sell Fees**: Implements a fee structure on transactions involving liquidity pairs, enhancing platform sustainability.
- **Ownership Management**: Two-step ownership transfer process for added security.
- **Fee Redistribution**: Accumulated fees can be redistributed to the platform.

## Contract Details

- **Token Name**: Pay It Forward
- **Symbol**: PIF
- **Initial Supply**: 500,000,000 PIF (500 million tokens)
- **Buy/Sell Fee**: 3% (300 basis points, adjustable)

## Installation

To set up this contract, clone the repo and make sure to install [Foundry](https://github.com/foundry-rs/foundry) and the required dependencies.

1. Install Foundry:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Install OpenZeppelin Contracts:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   ```

## Usage

After installing the dependencies, you can compile and deploy the PIF token contract using Foundry commands.

- **Compile**: 
  ```bash
  forge build
  ```

- **Deploy**: 
  ```bash
  forge create src/PIFToken.sol:PIFToken
  ```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.