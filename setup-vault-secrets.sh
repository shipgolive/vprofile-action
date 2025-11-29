#!/bin/bash

export VAULT_ADDR="http://aa0f32b0720c6422ba63eadd3b2fc4e5-874159703.us-east-2.elb.amazonaws.com:8200"

echo "🔐 Setting up Vault secrets with transit encryption..."

# Get root token (you'll need to provide this)
echo "Enter Vault root token:"
read -s VAULT_TOKEN
export VAULT_TOKEN

# Enable transit secrets engine
echo "Enabling transit secrets engine..."
vault secrets enable transit

# Create encryption key
echo "Creating encryption key..."
vault write -f transit/keys/vprofile-key

# Enable KV secrets engine
echo "Enabling KV secrets engine..."
vault secrets enable -path=secret kv-v2

# Encrypt and store DB password
echo "Enter MySQL root password:"
read -s DB_PASS
DB_ENCRYPTED=$(echo -n "$DB_PASS" | base64 | vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=-)
vault kv put secret/vprofile db-pass="$DB_ENCRYPTED"

# Encrypt and store RMQ password  
echo "Enter RabbitMQ password:"
read -s RMQ_PASS
RMQ_ENCRYPTED=$(echo -n "$RMQ_PASS" | base64 | vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=-)
vault kv patch secret/vprofile rmq-pass="$RMQ_ENCRYPTED"

# Create policy for vprofile
echo "Creating vprofile policy..."
vault policy write vprofile-policy - <<EOF
path "secret/data/vprofile" {
  capabilities = ["read"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}
EOF

# Enable Kubernetes auth
echo "Enabling Kubernetes auth..."
vault auth enable kubernetes

echo "✅ Vault secrets configured with transit encryption!"
echo "Next steps:"
echo "1. Run the Kubernetes auth setup"
echo "2. Deploy the updated manifests"