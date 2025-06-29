use anyhow::{Result, Context};
use sp_core::crypto::{Ss58Codec, Ss58AddressFormat};
use std::str::FromStr;

/// Validate a Substrate address
pub fn validate_address(address: &str) -> bool {
    sp_core::crypto::AccountId32::from_ss58check(address).is_ok()
}

/// Convert a hex public key to a Substrate address
pub fn pubkey_to_address(pubkey: &str, format: Option<Ss58AddressFormat>) -> Result<String> {
    let format = format.unwrap_or(Ss58AddressFormat::PolkadotAccount);
    
    let pubkey_bytes = hex::decode(pubkey)
        .context("Invalid public key hex string")?;
    
    if pubkey_bytes.len() != 32 {
        return Err(anyhow::anyhow!("Public key must be 32 bytes"));
    }
    
    let mut bytes = [0u8; 32];
    bytes.copy_from_slice(&pubkey_bytes);
    
    let account_id = sp_core::crypto::AccountId32::from(bytes);
    Ok(account_id.to_ss58check_with_version(format))
}

/// Convert a Substrate address to a hex public key
pub fn address_to_pubkey(address: &str) -> Result<String> {
    let account_id = sp_core::crypto::AccountId32::from_ss58check(address)
        .context("Invalid address")?;
    
    Ok(hex::encode(account_id.0))
}

/// Convert a network name to its Ss58AddressFormat
pub fn network_to_format(network: &str) -> Result<Ss58AddressFormat> {
    match network.to_lowercase().as_str() {
        "polkadot" => Ok(Ss58AddressFormat::PolkadotAccount),
        "kusama" => Ok(Ss58AddressFormat::KusamaAccount),
        "substrate" => Ok(Ss58AddressFormat::SubstrateAccount),
        _ => {
            // Try to parse as a number
            let format_num = u16::from_str(network)
                .context("Unknown network name and not a valid format number")?;
            
            Ok(Ss58AddressFormat::custom(format_num))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_address_conversions() {
        // Example Polkadot address and corresponding public key
        let address = "15oF4uVJwmo4TdGW7VfQxNLavjCXviqxT9S1MgbjMNHr6Sp5";
        let pubkey = "d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d";
        
        assert!(validate_address(address));
        
        let derived_pubkey = address_to_pubkey(address).unwrap();
        assert_eq!(derived_pubkey, pubkey);
        
        let derived_address = pubkey_to_address(pubkey, Some(Ss58AddressFormat::PolkadotAccount)).unwrap();
        assert_eq!(derived_address, address);
    }
    
    #[test]
    fn test_network_formats() {
        assert_eq!(
            network_to_format("polkadot").unwrap(), 
            Ss58AddressFormat::PolkadotAccount
        );
        
        assert_eq!(
            network_to_format("kusama").unwrap(), 
            Ss58AddressFormat::KusamaAccount
        );
        
        // Test custom format
        assert_eq!(
            network_to_format("42").unwrap(), 
            Ss58AddressFormat::custom(42)
        );
    }
} 