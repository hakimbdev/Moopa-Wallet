use anyhow::{Result, Context};
use substrate_api_client::{
    rpc::WsRpcClient,
    Api, XtStatus,
};
use parity_scale_codec::Compact;
use sp_core::crypto::Ss58Codec;
use sp_runtime::traits::IdentifyAccount;
use sp_runtime::{
    generic::Era,
    MultiSignature,
};

use crate::wallet::Wallet;

/// Get the balance of an account
pub async fn get_balance(address: &str, endpoint: &str) -> Result<String> {
    // Connect to the node
    let client = WsRpcClient::new(endpoint)
        .context("Failed to create RPC client")?;
    let api = Api::new(client)
        .context("Failed to create API client")?;
    
    // Convert the address to AccountId
    let account_id = api.get_account_id_from_ss58(address)
        .context("Failed to convert address to account ID")?;
    
    // Query the account balance (assumes the standard Balances pallet)
    let balance = api.get_account_data(&account_id)
        .context("Failed to get account data")?
        .map(|data| data.free)
        .unwrap_or_default();
    
    // Convert to a human-readable format (assuming the chain's token has 12 decimals like DOT)
    let balance_str = format!("{}.{:012}", 
        balance / 1_000_000_000_000, 
        balance % 1_000_000_000_000);
    
    Ok(balance_str.trim_end_matches('0').trim_end_matches('.').to_string())
}

/// Transfer funds from one account to another
pub async fn transfer(wallet: &Wallet, to: &str, amount_str: &str, endpoint: &str) -> Result<String> {
    // Connect to the node
    let client = WsRpcClient::new(endpoint)
        .context("Failed to create RPC client")?;
    let api = Api::new(client)
        .context("Failed to create API client")?;
    
    // Get the keypair from the wallet
    let pair = wallet.pair.as_ref()
        .context("No private key available in wallet")?;
    
    // Parse amount (assuming 12 decimals like DOT)
    let amount = parse_amount(amount_str)?;
    
    // Get the recipient's AccountId
    let to_account = api.get_account_id_from_ss58(to)
        .context("Failed to convert recipient address to account ID")?;
    
    // Create the transfer extrinsic
    let xt = api.create_signed(
        pair,
        // Call the transfer function from the Balances pallet
        |call_params| {
            call_params.function = "transfer".into();
            call_params.module = "Balances".into();
            call_params.params = vec![
                // Destination
                serde_json::to_value(&to_account)
                    .context("Failed to serialize recipient account ID")?,
                // Amount with compact encoding
                serde_json::to_value(&Compact(amount))
                    .context("Failed to serialize amount")?,
            ];
            Ok(call_params)
        },
        Era::Immortal,
    )?;
    
    // Submit the extrinsic and wait for it to be in block
    let tx_hash = api.send_extrinsic(xt.hex_encode(), XtStatus::InBlock)
        .context("Failed to send transaction")?;
    
    Ok(tx_hash)
}

/// Parse a human-readable amount string to chain format
fn parse_amount(amount_str: &str) -> Result<u128> {
    let parts: Vec<&str> = amount_str.split('.').collect();
    
    match parts.as_slice() {
        [whole] => {
            // No decimal part
            let whole_part: u128 = whole.parse()
                .context("Invalid amount format")?;
            Ok(whole_part * 1_000_000_000_000) // 12 decimals like DOT
        }
        [whole, decimal] => {
            // Has decimal part
            let whole_part: u128 = whole.parse()
                .context("Invalid amount format")?;
            
            // Pad or truncate the decimal part to 12 digits
            let mut decimal_str = decimal.to_string();
            if decimal_str.len() > 12 {
                decimal_str = decimal_str[0..12].to_string();
            } else {
                decimal_str.push_str(&"0".repeat(12 - decimal_str.len()));
            }
            
            let decimal_part: u128 = decimal_str.parse()
                .context("Invalid decimal part in amount")?;
            
            Ok(whole_part * 1_000_000_000_000 + decimal_part)
        }
        _ => Err(anyhow::anyhow!("Invalid amount format")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_amount() {
        assert_eq!(parse_amount("5").unwrap(), 5_000_000_000_000);
        assert_eq!(parse_amount("5.5").unwrap(), 5_500_000_000_000);
        assert_eq!(parse_amount("0.000000000001").unwrap(), 1);
        assert_eq!(parse_amount("1.000000000001").unwrap(), 1_000_000_000_001);
    }
} 