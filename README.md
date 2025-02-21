# Azure Key Vault Secret Migration Script

## Overview
This PowerShell script automates the process of migrating secrets from a source Azure Key Vault to a target Azure Key Vault across different subscriptions. It ensures that only unique secrets are copied and avoids overwriting existing secrets in the target Key Vault.

## Prerequisites
Before using this script, ensure you have the following:

- Azure CLI installed and authenticated (`az login`)
- Azure PowerShell module installed (`Install-Module -Name Az -Scope CurrentUser`)
- Necessary permissions on both source and target Key Vaults
- Subscriptions for both source and target Key Vaults

## Usage

### 1. Update the Script with Your Details
Modify the following placeholders in the script:

```powershell
$sourceSubscriptionId = "<Source_Subscription_ID>"
$targetSubscriptionId = "<Target_Subscription_ID>"
$sourceKeyVaultName = "<Source_Key_Vault_Name>"
$targetKeyVaultName = "<Target_Key_Vault_Name>"
```

### 2. Run the Script
Execute the script in PowerShell:

```powershell
.\kv-secret-copy.ps1
```

### 3. Handling Special Characters in Secrets
Secrets with special characters like `<` or `>` are handled correctly by ensuring:
- The script retrieves secret values as plain text using `-AsPlainText`.
- The script escapes newline characters properly.
- Secrets are stored and retrieved without data corruption.

### 4. Skipping Existing Secrets
If a secret with the same name exists in the target Key Vault, the script skips it. To override this behavior and force updates, modify the script to remove the existing check.

## Notes
- This script does **not** delete secrets from the source Key Vault.
- Ensure proper security practices while handling secrets.
- Use Azure Key Vault access policies to limit exposure.

