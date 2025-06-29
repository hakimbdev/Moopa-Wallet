# SWallet - Substrate Wallet

A command-line wallet application for Substrate-based blockchains like Polkadot, Kusama, and others.

## Features

- Create and manage wallet accounts
- Generate and restore wallets from mnemonics and seeds
- Check account balances
- Transfer funds between accounts
- Supports multiple Substrate-based networks

## Installation

### Prerequisites

- Rust and Cargo (latest stable version)

### Building from source

```bash
# Clone the repository
git clone https://github.com/yourusername/swallet.git
cd swallet

# Build the wallet
cargo build --release

# The binary will be available at ./target/release/swallet
```

## Usage

### Creating a new wallet

```bash
# Create a new wallet and save it to the default location (./wallet.json)
./swallet create

# Create a wallet and specify a custom path
./swallet create --path ~/my-wallets/polkadot-wallet.json
```

### Importing an existing wallet

```bash
# Import from a mnemonic phrase
./swallet import --seed "word1 word2 ... word12" --path ./my-wallet.json

# Import from a hex seed
./swallet import --seed "0x1234567890abcdef..." --path ./my-wallet.json
```

### Checking account information

```bash
# View account details
./swallet account --wallet ./wallet.json
```

### Checking balance

```bash
# Check balance on the local node
./swallet balance --wallet ./wallet.json

# Check balance on a specific node
./swallet balance --wallet ./wallet.json --endpoint wss://rpc.polkadot.io
```

### Transferring funds

```bash
# Transfer 1.5 DOT to another account
./swallet transfer --wallet ./wallet.json --to 15oF4uVJwmo4TdGW7VfQxNLavjCXviqxT9S1MgbjMNHr6Sp5 --amount 1.5 --endpoint wss://rpc.polkadot.io
```

## Security Recommendations

- Always keep your mnemonic phrase and private keys secure.
- Consider using a hardware wallet for large amounts.
- Verify the recipient address before making transfers.
- Back up your wallet files in secure locations.

## Development

### Running tests

```bash
cargo test
```

### Building documentation

```bash
cargo doc --open
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

Built with [Substrate](https://substrate.dev/) and the Substrate API client. # Moopa-Wallet
