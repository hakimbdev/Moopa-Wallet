# SWallet PowerShell Demo Script - Automatic Demo Version
# This script automatically demonstrates wallet functionality

Write-Host "=== SWallet Automatic Demo ===" -ForegroundColor Cyan

# Create a mock wallet with a random address
Write-Host "`n[1] Creating a new wallet..." -ForegroundColor Green
$addressPrefix = "15oF4uVJwmo"
$addressSuffix = -join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
$address = "$addressPrefix$addressSuffix"

$words = @("abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse", 
           "access", "accident", "account", "accuse", "achieve", "acid", "acoustic", "acquire", "across", "act")
$mnemonic = ($words | Get-Random -Count 12) -join " "

# Create wallet file
$wallet = @{
    address = $address
    public_key = "0x" + -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
    mnemonic = $mnemonic
    balance = 0
}

$wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"

Write-Host "Wallet created successfully!" -ForegroundColor Green
Write-Host "Address: $($wallet.address)"
Write-Host "Public Key: $($wallet.public_key)"
Write-Host "Mnemonic: $($wallet.mnemonic)"
Start-Sleep -Seconds 2

# Show wallet information
Write-Host "`n[2] Reading wallet information..." -ForegroundColor Green
$wallet = Get-Content -Path "wallet.json" | ConvertFrom-Json
Write-Host "Wallet Address: $($wallet.address)"
Write-Host "Public Key: $($wallet.public_key)"
Start-Sleep -Seconds 2

# Check and update balance
Write-Host "`n[3] Checking wallet balance..." -ForegroundColor Green
Write-Host "Connecting to Substrate node..."
Start-Sleep -Seconds 1
Write-Host "Connected!"

# Add initial funds for testing
$wallet.balance = 10
$wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
Write-Host "Current balance: $($wallet.balance) DOT"
Start-Sleep -Seconds 2

# Make a transfer
Write-Host "`n[4] Making a test transfer..." -ForegroundColor Green
$recipientAddress = "14oF5uVJwmo" + (-join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_}))
$amount = 2.5

Write-Host "Transferring $amount DOT to $recipientAddress"
Write-Host "Connecting to Substrate node..."
Start-Sleep -Seconds 1
Write-Host "Submitting transaction..."
Start-Sleep -Seconds 2

# Generate a mock transaction hash
$txHash = "0x" + -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})

$wallet.balance = $wallet.balance - $amount
$wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"

Write-Host "Transfer successful!" -ForegroundColor Green
Write-Host "Transaction hash: $txHash"
Write-Host "New balance: $($wallet.balance) DOT"
Start-Sleep -Seconds 2

# Check final balance
Write-Host "`n[5] Checking final balance..." -ForegroundColor Green
$wallet = Get-Content -Path "wallet.json" | ConvertFrom-Json
Write-Host "Final wallet balance: $($wallet.balance) DOT"

Write-Host "`nSWallet demo completed successfully!" -ForegroundColor Cyan
Write-Host "This was a simulation of the functionality that would be available"
Write-Host "in the full Substrate wallet implementation." 