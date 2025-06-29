use anyhow::Result;
use clap::{Parser, Subcommand};
use std::path::PathBuf;

mod wallet;
mod rpc;
mod utils;

#[derive(Parser)]
#[clap(name = "swallet", about = "Substrate Wallet CLI")]
struct Cli {
    #[clap(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a new wallet
    Create {
        /// Path to store the wallet file
        #[clap(short, long, default_value = "./wallet.json")]
        path: PathBuf,
    },
    /// Import an existing wallet from seed or mnemonic
    Import {
        /// Seed or mnemonic phrase
        #[clap(short, long)]
        seed: String,
        /// Path to store the wallet file
        #[clap(short, long, default_value = "./wallet.json")]
        path: PathBuf,
    },
    /// Get account information
    Account {
        /// Path to the wallet file
        #[clap(short, long, default_value = "./wallet.json")]
        wallet: PathBuf,
    },
    /// Check wallet balance
    Balance {
        /// Path to the wallet file
        #[clap(short, long, default_value = "./wallet.json")]
        wallet: PathBuf,
        /// RPC endpoint URL
        #[clap(short, long, default_value = "ws://127.0.0.1:9944")]
        endpoint: String,
    },
    /// Transfer funds
    Transfer {
        /// Path to the wallet file
        #[clap(short, long, default_value = "./wallet.json")]
        wallet: PathBuf,
        /// Recipient address
        #[clap(short, long)]
        to: String,
        /// Amount to transfer
        #[clap(short, long)]
        amount: String,
        /// RPC endpoint URL
        #[clap(short, long, default_value = "ws://127.0.0.1:9944")]
        endpoint: String,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Create { path } => {
            let wallet = wallet::create_wallet()?;
            wallet::save_wallet(&wallet, path)?;
            println!("Wallet created successfully at {:?}", path);
            println!("Address: {}", wallet.address);
            println!("Mnemonic (keep this secret!): {}", wallet.mnemonic);
        }
        Commands::Import { seed, path } => {
            let wallet = wallet::import_wallet(seed)?;
            wallet::save_wallet(&wallet, path)?;
            println!("Wallet imported successfully at {:?}", path);
            println!("Address: {}", wallet.address);
        }
        Commands::Account { wallet } => {
            let wallet = wallet::load_wallet(wallet)?;
            println!("Address: {}", wallet.address);
        }
        Commands::Balance { wallet, endpoint } => {
            let wallet = wallet::load_wallet(wallet)?;
            let balance = rpc::get_balance(&wallet.address, endpoint).await?;
            println!("Balance: {} tokens", balance);
        }
        Commands::Transfer { wallet, to, amount, endpoint } => {
            let wallet = wallet::load_wallet(wallet)?;
            let txn_hash = rpc::transfer(&wallet, to, amount, endpoint).await?;
            println!("Transfer successful!");
            println!("Transaction hash: {}", txn_hash);
        }
    }

    Ok(())
} 