# SWallet Server - A simple HTTP server exposing wallet functionality
# Requires PowerShell 7+ for better HTTP handling

# Define the port to listen on
$port = 8080

# Load existing wallet or create new one
function Initialize-Wallet {
    if (Test-Path "wallet.json") {
        $script:wallet = Get-Content -Path "wallet.json" | ConvertFrom-Json
        Write-Host "Loaded existing wallet with address: $($script:wallet.address)" -ForegroundColor Green
    } else {
        # Create a new wallet
        $addressPrefix = "15oF4uVJwmo"
        $addressSuffix = -join ((65..90) + (97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
        $address = "$addressPrefix$addressSuffix"
        
        $words = @("abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse", 
                   "access", "accident", "account", "accuse", "achieve", "acid", "acoustic", "acquire", "across", "act")
        $mnemonic = ($words | Get-Random -Count 12) -join " "
        
        $script:wallet = @{
            address = $address
            public_key = "0x" + -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
            mnemonic = $mnemonic
            balance = 10  # Starting with test balance
        }
        
        $script:wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
        Write-Host "Created new wallet with address: $($script:wallet.address)" -ForegroundColor Green
    }
}

# Process API requests
function Process-Request($request) {
    $response = @{
        statusCode = 200
        contentType = "application/json"
        body = ""
    }
    
    try {
        # Extract the endpoint from the URL
        $endpoint = $request.Url.LocalPath
        
        switch ($endpoint) {
            # Get wallet info
            "/api/wallet" {
                if ($request.HttpMethod -eq "GET") {
                    # Return wallet info (excluding mnemonic for security)
                    $walletInfo = @{
                        address = $script:wallet.address
                        public_key = $script:wallet.public_key
                        balance = $script:wallet.balance
                    }
                    $response.body = $walletInfo | ConvertTo-Json
                }
            }
            
            # Check balance
            "/api/balance" {
                if ($request.HttpMethod -eq "GET") {
                    # Simulate blockchain connection
                    Start-Sleep -Milliseconds 500
                    
                    $balanceInfo = @{
                        address = $script:wallet.address
                        balance = $script:wallet.balance
                        currency = "DOT"
                    }
                    $response.body = $balanceInfo | ConvertTo-Json
                }
            }
            
            # Make a transfer
            "/api/transfer" {
                if ($request.HttpMethod -eq "POST") {
                    # Read the request body
                    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                    $body = $reader.ReadToEnd()
                    $transferData = $body | ConvertFrom-Json
                    
                    # Validate transfer
                    if ($null -eq $transferData.to -or $null -eq $transferData.amount) {
                        $response.statusCode = 400
                        $response.body = @{ error = "Missing recipient or amount" } | ConvertTo-Json
                    }
                    elseif ($transferData.amount -gt $script:wallet.balance) {
                        $response.statusCode = 400
                        $response.body = @{ error = "Insufficient funds" } | ConvertTo-Json
                    }
                    else {
                        # Simulate transaction
                        Start-Sleep -Milliseconds 1000
                        
                        # Generate transaction hash
                        $txHash = "0x" + -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
                        
                        # Update balance
                        $script:wallet.balance = $script:wallet.balance - $transferData.amount
                        $script:wallet | ConvertTo-Json | Out-File -FilePath "wallet.json"
                        
                        $response.body = @{
                            success = $true
                            txHash = $txHash
                            from = $script:wallet.address
                            to = $transferData.to
                            amount = $transferData.amount
                            newBalance = $script:wallet.balance
                        } | ConvertTo-Json
                    }
                }
                else {
                    $response.statusCode = 405
                    $response.body = @{ error = "Method not allowed" } | ConvertTo-Json
                }
            }
            
            # Root path - return HTML with usage instructions
            "/" {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>SWallet API Server</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
        h1, h2 { color: #333; }
    </style>
</head>
<body>
    <h1>SWallet API Server</h1>
    <p>Welcome to the SWallet API Server. Use the following endpoints:</p>
    
    <h2>GET /api/wallet</h2>
    <p>Get wallet information</p>
    <pre>curl http://localhost:$port/api/wallet</pre>
    
    <h2>GET /api/balance</h2>
    <p>Check wallet balance</p>
    <pre>curl http://localhost:$port/api/balance</pre>
    
    <h2>POST /api/transfer</h2>
    <p>Make a transfer</p>
    <pre>curl -X POST http://localhost:$port/api/transfer -H "Content-Type: application/json" -d '{"to":"RECIPIENT_ADDRESS","amount":1.5}'</pre>
</body>
</html>
"@
                $response.contentType = "text/html"
                $response.body = $html
            }
            
            default {
                $response.statusCode = 404
                $response.body = @{ error = "Endpoint not found" } | ConvertTo-Json
            }
        }
    }
    catch {
        $response.statusCode = 500
        $response.body = @{ error = $_.Exception.Message } | ConvertTo-Json
    }
    
    return $response
}

# Main server loop
function Start-Server {
    try {
        # Initialize the wallet
        Initialize-Wallet
        
        # Create HTTP listener
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$port/")
        $listener.Start()
        
        Write-Host "SWallet server started at http://localhost:$port/" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop the server"
        
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # Log the request
            Write-Host "$($request.HttpMethod) $($request.Url.LocalPath)" -ForegroundColor Yellow
            
            # Process the request
            $result = Process-Request $request
            
            # Set the response
            $response.StatusCode = $result.statusCode
            $response.ContentType = $result.contentType
            
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($result.body)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            
            $response.Close()
        }
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    finally {
        if ($null -ne $listener) {
            $listener.Stop()
            $listener.Close()
            Write-Host "Server stopped" -ForegroundColor Cyan
        }
    }
}

# Start the server
Start-Server 