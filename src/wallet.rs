use anyhow::{Result, Context};
use sp_core::{
    crypto::{Ss58Codec, Ss58AddressFormat},
    sr25519::{Pair, Public},
    Pair as PairT,
};
use std::{
    fs,
    path::Path,
};
use serde::{Serialize, Deserialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum WalletError {
    #[error("Invalid seed or mnemonic phrase")]
    InvalidSeed,
    #[error("Failed to load wallet: {0}")]
    LoadError(String),
    #[error("Failed to save wallet: {0}")]
    SaveError(String),
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Wallet {
    pub address: String,
    pub public_key: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mnemonic: Option<String>,
    #[serde(skip)]
    pub pair: Option<Pair>,
}

/// Create a new wallet with a random seed
pub fn create_wallet() -> Result<Wallet> {
    // Generate random mnemonic (24 words seed phrase)
    let (pair, phrase, _) = Pair::generate_with_phrase(None);
    let public: Public = pair.public();
    
    // Convert to SS58 address (Substrate address format)
    let address = public.to_ss58check_with_version(Ss58AddressFormat::PolkadotAccount);
    
    Ok(Wallet {
        address,
        public_key: hex::encode(public.0),
        mnemonic: Some(phrase),
        pair: Some(pair),
    })
}

/// Import a wallet from seed or mnemonic
pub fn import_wallet(seed: &str) -> Result<Wallet> {
    // Try to interpret as mnemonic phrase first
    let pair = Pair::from_phrase(seed, None)
        .or_else(|_| {
            // If not a phrase, try to use as raw seed
            if let Ok(seed_bytes) = hex::decode(seed) {
                Pair::from_seed_slice(&seed_bytes)
            } else {
                Err(sp_core::crypto::SecretStringError::InvalidSeed)
            }
        })
        .map_err(|_| WalletError::InvalidSeed)?;

    let public: Public = pair.public();
    let address = public.to_ss58check_with_version(Ss58AddressFormat::PolkadotAccount);
    
    Ok(Wallet {
        address,
        public_key: hex::encode(public.0),
        mnemonic: None, // We don't store the mnemonic for imported wallets
        pair: Some(pair),
    })
}

/// Save wallet to file
pub fn save_wallet(wallet: &Wallet, path: &Path) -> Result<()> {
    let json = serde_json::to_string_pretty(wallet)
        .context("Failed to serialize wallet")?;
    
    fs::write(path, json)
        .context(format!("Failed to write wallet to {:?}", path))?;
    
    Ok(())
}

/// Load wallet from file
pub fn load_wallet(path: &Path) -> Result<Wallet> {
    let data = fs::read_to_string(path)
        .context(format!("Failed to read wallet file at {:?}", path))?;
    
    let mut wallet: Wallet = serde_json::from_str(&data)
        .context("Failed to parse wallet file")?;
    
    // If we have a mnemonic, reconstruct the pair
    if let Some(ref mnemonic) = wallet.mnemonic {
        if let Ok((pair, _, _)) = Pair::from_phrase(mnemonic, None) {
            wallet.pair = Some(pair);
        }
    }
    
    Ok(wallet)
}

/// Sign data using the wallet's private key
pub fn sign(wallet: &Wallet, data: &[u8]) -> Result<Vec<u8>> {
    let pair = wallet.pair.as_ref()
        .ok_or_else(|| WalletError::LoadError("No private key available".to_string()))?;
    
    // Sign the data
    let signature = pair.sign(data);
    
    Ok(signature.0.to_vec())
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    
    #[test]
    fn test_wallet_create_and_save() {
        let dir = tempdir().unwrap();
        let wallet_path = dir.path().join("test_wallet.json");
        
        let wallet = create_wallet().unwrap();
        save_wallet(&wallet, &wallet_path).unwrap();
        
        assert!(wallet_path.exists());
        
        let loaded_wallet = load_wallet(&wallet_path).unwrap();
        assert_eq!(wallet.address, loaded_wallet.address);
        assert_eq!(wallet.public_key, loaded_wallet.public_key);
    }
    
    #[test]
    fn test_wallet_sign() {
        let wallet = create_wallet().unwrap();
        let data = b"test message";
        
        let signature = sign(&wallet, data).unwrap();
        assert!(!signature.is_empty());
        
        // Verify signature (using substrate verification)
        let result = sp_core::sr25519::Signature::from_slice(&signature)
            .map(|sig| {
                let public = Public::from_hex(&wallet.public_key).unwrap();
                sp_core::sr25519::verify(&sig, data, &public)
            });
        
        assert!(result.unwrap());
    }
} 