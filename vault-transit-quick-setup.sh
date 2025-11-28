#!/bin/bash
# Quick setup for existing Vault instance

VAULT_URL="http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"

echo "🔐 Configuring Transit Engine on existing Vault..."
echo "Vault URL: $VAULT_URL"

# Set Vault address
export VAULT_ADDR=$VAULT_URL

# Enable Transit engine
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/vprofile-key

# Create policy
vault policy write transit-policy - <<EOF
path "transit/encrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}
EOF

# Create token
TRANSIT_TOKEN=$(vault token create -policy=transit-policy -format=json | jq -r '.auth.client_token')
echo "Transit Token: $TRANSIT_TOKEN"

# Test encryption
echo "Testing encryption..."
ENCRYPTED=$(vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=$(echo -n "Hello Vault!" | base64))
echo "Encrypted: $ENCRYPTED"

DECRYPTED=$(vault write -field=plaintext transit/decrypt/vprofile-key ciphertext=$ENCRYPTED)
echo "Decrypted: $(echo $DECRYPTED | base64 -d)"

echo "✅ Transit engine ready!"
echo "Use token: $TRANSIT_TOKEN"