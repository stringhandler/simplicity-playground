# Simplicity Codespace Quickstart

This GitHub Codespace provides a ready-to-use environment for working with Simplicity programs on Liquid testnet.

## Quick Start Options

You can either:
- **Option 1:** Run the automated demo script: `./p2ms-demo.sh`
- **Option 2:** Follow the manual steps below to understand each step

## Prerequisites

The Codespace comes pre-configured with:
- `simc` - Simplicity compiler
- `hal-simplicity` - HAL tools for Simplicity
- `lwk_cli` - Liquid Wallet Kit CLI

## Getting Started

Follow these steps to compile a Simplicity program and fund it on Liquid testnet:

### 1. Compile the Simplicity Program

Run the compiler on the example P2PK (Pay-to-Public-Key) program:

```bash
simc p2pk.simf
```

**Important:** Take note of the entire program output. You'll need this for the next step.

### 2. Get Program Information

Paste the program output from step 1 into the `hal-simplicity` info command:

```bash
hal-simplicity simplicity info <program>
```

Replace `<program>` with the actual output from the `simc` command.

### 3. Extract Key Information

From the output of the previous command, take note of:
- **`cmr`** - The commitment Merkle root (program identifier)
- **`liquid_testnet_address_unconf`** - The Liquid testnet address for this program

### 4. Fund the Address

1. Go to the [Liquid Testnet Faucet](https://liquidtestnet.com/faucet)
2. Paste the `liquid_testnet_address_unconf` from step 3
3. Click "Send"
4. **Take note of the transaction ID** that appears after sending


