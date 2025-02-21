# Define source and target details
$sourceSubscriptionId = "<Source_Subscription_ID>"
$targetSubscriptionId = "<Target_Subscription_ID>"
$sourceKeyVaultName = "<Source_Key_Vault_Name>"
$targetKeyVaultName = "<Target_Key_Vault_Name>"


Write-Host "Switching to source subscription: $sourceSubscriptionId"
az account set --subscription $sourceSubscriptionId

Write-Host "Fetching secrets from source Key Vault: $sourceKeyVaultName"
$secrets = Get-AzKeyVaultSecret -VaultName $sourceKeyVaultName

if (-not $secrets) {
    Write-Host "No secrets found in $sourceKeyVaultName." -ForegroundColor Yellow
    return
}

$secretsData = @{}

foreach ($secret in $secrets) {
    try {
        Write-Host "Retrieving value for secret: $($secret.Name)"
        
        # Get secret value in plain text
        $secretValue = Get-AzKeyVaultSecret -VaultName $sourceKeyVaultName -Name $secret.Name -AsPlainText

        if (-not $secretValue) {
            Write-Host "Skipping secret '$($secret.Name)' as it has no value." -ForegroundColor Yellow
            continue
        }

        # Store the secret name and value in the hashtable
        $secretsData[$secret.Name] = $secretValue
    } catch {
        Write-Host "Error retrieving secret '$($secret.Name)': $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Switch to the target subscription
Write-Host "Switching to target subscription: $targetSubscriptionId"
az account set --subscription $targetSubscriptionId

# Fetch existing secrets in the target Key Vault to check for duplicates
Write-Host "Fetching existing secrets from target Key Vault: $targetKeyVaultName"
$existingSecrets = az keyvault secret list --vault-name $targetKeyVaultName --query "[].name" -o tsv

# Copy all secrets to the target Key Vault
foreach ($secretName in $secretsData.Keys) {
    if ($existingSecrets -contains $secretName) {
        Write-Host "Skipping secret '$secretName' as it already exists in the target Key Vault." -ForegroundColor Yellow
        continue
    }

    try {
        Write-Host "Copying secret: $secretName to target Key Vault: $targetKeyVaultName"
        
        # Get the secret value from the hashtable
        $secretValue = $secretsData[$secretName]

        # Save the secret value to a temporary file
        $tempFilePath = "$env:TEMP\$secretName.txt"
        Set-Content -Path $tempFilePath -Value $secretValue

        # Set the secret value in the target Key Vault using the file
        az keyvault secret set --name $secretName --vault-name $targetKeyVaultName --file $tempFilePath | Out-Null

        # Clean up the temporary file
        Remove-Item -Path $tempFilePath -Force
    } catch {
        Write-Host "Error copying secret '$secretName': $($_.Exception.Message)" -ForegroundColor Red
    }
}

