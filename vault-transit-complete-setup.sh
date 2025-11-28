#!/bin/bash
# Complete Vault Transit Setup for Encryption-as-a-Service

VAULT_URL="http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"
export VAULT_ADDR=$VAULT_URL

echo "🔐 Setting up Vault Transit Engine for Encryption-as-a-Service..."

# Check if authenticated
echo "Checking Vault authentication..."
vault token lookup || {
  echo "❌ Not authenticated. Please run: vault auth -method=userpass username=admin"
  echo "Or set VAULT_TOKEN environment variable"
  exit 1
}

# 1. Enable Transit secrets engine
echo "Enabling Transit engine..."
vault secrets enable transit

# 2. Create encryption key for vprofile
echo "Creating encryption key..."
vault write -f transit/keys/vprofile-key

# 3. Create policy for vprofile application
echo "Creating vprofile policy..."
vault policy write vprofile-policy - <<EOF
path "transit/encrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/datakey/plaintext/vprofile-key" {
  capabilities = ["update"]
}
path "transit/datakey/wrapped/vprofile-key" {
  capabilities = ["update"]
}
EOF

# 4. Create service account token for vprofile app
echo "Creating service token..."
VPROFILE_TOKEN=$(vault token create -policy=vprofile-policy -ttl=24h -format=json | grep -o '"client_token":"[^"]*"' | cut -d'"' -f4)
echo "VPROFILE_TOKEN: $VPROFILE_TOKEN"

# 5. Test encryption/decryption
echo "Testing encryption..."
PLAINTEXT="database_password_123"
ENCODED=$(echo -n "$PLAINTEXT" | base64)
ENCRYPTED=$(vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=$ENCODED)
echo "Original: $PLAINTEXT"
echo "Encrypted: $ENCRYPTED"

DECRYPTED_ENCODED=$(vault write -field=plaintext transit/decrypt/vprofile-key ciphertext=$ENCRYPTED)
DECRYPTED=$(echo $DECRYPTED_ENCODED | base64 -d)
echo "Decrypted: $DECRYPTED"

echo "✅ Transit setup complete!"
echo "Token for vprofile app: $VPROFILE_TOKEN"