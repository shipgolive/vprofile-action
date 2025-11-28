#!/bin/bash
# Simple Vault Transit Setup - Set VAULT_TOKEN first

export VAULT_ADDR="http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"

echo "🔐 Setting up Vault Transit Engine..."
echo "Make sure VAULT_TOKEN is set!"

# Enable Transit engine
vault secrets enable transit

# Create encryption key
vault write -f transit/keys/vprofile-key

# Create policy
vault policy write vprofile-policy - <<EOF
path "transit/encrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}
EOF

# Create token
vault token create -policy=vprofile-policy -ttl=24h

echo "✅ Setup complete! Copy the token above for your application."