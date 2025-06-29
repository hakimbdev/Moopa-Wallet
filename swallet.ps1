# SWallet PowerShell Demo Script
# This is a simplified demonstration of the SWallet functionality
# It simulates wallet creation, balance checking, and transfers

function Show-Menu {
    Clear-Host
    Write-Host "=== SWallet Demo ==="
    Write-Host "1: Create a new wallet"
    Write-Host "2: Show wallet info"
    Write-Host "3: Check balance"
    Write-Host "4: Transfer funds"
    Write-Host "5: Exit"
    Write-Host "===================="
}

function Create-Wallet {
    # Generate a mock random address and mnemonic
    $addressPrefix = "15oF4uVJwmo"
    $addressSuffix = -join ((65..90) + (97..122) | Get-Random -Count 30 | ForEach-Object {[char]$_})
    $address = "$addressPrefix$addressSuffix"
    
    $words = @("abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse", 
               "access", "accident", "account", "accuse", "achieve", "acid", "acoustic", "acquire", "across", "act", 
               "action", "actor", "actual", "adapt", "add")
    $mnemonic = -join (($words | Get-Random -Count 12) -join " ")
    
    # Create wallet file
    $wallet = @{
        address = $address
        public_key = "0x" + -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
        mnemonic = $mnemonic
        balance = 0
    }
    
    $wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
    
    Write-Host "Wallet created successfully"
    Write-Host "Address: $($wallet.address)"
    Write-Host "Mnemonic (keep this secret!): $($wallet.mnemonic)"
}

function Show-WalletInfo {
    if (-not (Test-Path "wallet.json")) {
        Write-Host "No wallet found. Please create a wallet first."
        return
    }
    
    $wallet = Get-Content -Path "wallet.json" | ConvertFrom-Json
    Write-Host "Wallet Address: $($wallet.address)"
    Write-Host "Public Key: $($wallet.public_key)"
}

function Check-Balance {
    if (-not (Test-Path "wallet.json")) {
        Write-Host "No wallet found. Please create a wallet first."
        return
    }
    
    $wallet = Get-Content -Path "wallet.json" | ConvertFrom-Json
    
    # Simulate RPC connection to blockchain
    Write-Host "Connecting to Substrate node..."
    Start-Sleep -Seconds 1
    Write-Host "Connected!"
    
    # Simulate balance check
    if (-not (Get-Member -InputObject $wallet -Name "balance" -MemberType Properties)) {
        $wallet | Add-Member -MemberType NoteProperty -Name "balance" -Value 0
    }
    
    Write-Host "Current balance: $($wallet.balance) DOT"
    
    # Add some test funds if balance is 0
    if ($wallet.balance -eq 0) {
        $wallet.balance = 10
        $wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
        Write-Host "Added test funds! New balance: $($wallet.balance) DOT"
    }
}

function Transfer-Funds {
    if (-not (Test-Path "wallet.json")) {
        Write-Host "No wallet found. Please create a wallet first."
        return
    }
    
    $wallet = Get-Content -Path "wallet.json" | ConvertFrom-Json
    
    if (-not (Get-Member -InputObject $wallet -Name "balance" -MemberType Properties)) {
        $wallet | Add-Member -MemberType NoteProperty -Name "balance" -Value 10
        $wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
    }
    
    if ($wallet.balance -eq 0) {
        Write-Host "Insufficient funds for transfer"
        return
    }
    
    $recipientAddress = Read-Host -Prompt "Enter recipient address (or press Enter for a random address)"
    
    if ([string]::IsNullOrWhiteSpace($recipientAddress)) {
        $addressPrefix = "14oF5uVJwmo"
        $addressSuffix = -join ((65..90) + (97..122) | Get-Random -Count 30 | ForEach-Object {[char]$_})
        $recipientAddress = "$addressPrefix$addressSuffix"
    }
    
    $amount = Read-Host -Prompt "Enter amount to transfer (available: $($wallet.balance) DOT)"
    
    if (-not [double]::TryParse($amount, [ref]$null)) {
        Write-Host "Invalid amount"
        return
    }
    
    $amountValue = [double]$amount
    
    if ($amountValue -gt $wallet.balance) {
        Write-Host "Insufficient funds"
        return
    }
    
    # Simulate transaction
    Write-Host "Connecting to Substrate node..."
    Start-Sleep -Seconds 1
    Write-Host "Submitting transaction..."
    Start-Sleep -Seconds 2
    
    # Generate a mock transaction hash
    $txHash = "0x" + -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
    
    $wallet.balance = $wallet.balance - $amountValue
    $wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
    
    Write-Host "Transfer successful!"
    Write-Host "Transferred $amountValue DOT to $recipientAddress"
    Write-Host "Transaction hash: $txHash"
    Write-Host "New balance: $($wallet.balance) DOT"
}

# Main program
$running = $true

while ($running) {
    Show-Menu
    $choice = Read-Host -Prompt "Enter your choice"
    
    switch ($choice) {
        "1" { Create-Wallet; Read-Host "Press Enter to continue..." }
        "2" { Show-WalletInfo; Read-Host "Press Enter to continue..." }
        "3" { Check-Balance; Read-Host "Press Enter to continue..." }
        "4" { Transfer-Funds; Read-Host "Press Enter to continue..." }
        "5" { $running = $false }
        default { Write-Host "Invalid choice"; Read-Host "Press Enter to continue..." }
    }
}

Write-Host "Thank you for using SWallet Demo!" 