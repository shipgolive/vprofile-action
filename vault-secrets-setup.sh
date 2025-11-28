#!/bin/bash
# Setup encrypted secrets in Vault

export VAULT_ADDR="http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"
export VAULT_TOKEN=root-token-123

echo "🔐 Storing encrypted secrets in Vault..."

# Enable KV secrets engine for storing encrypted passwords
vault secrets enable -path=secret kv-v2

# Encrypt and store RabbitMQ password
RMQ_ENCRYPTED=$(vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=$(echo -n "guest123" | base64))
vault kv put secret/vprofile rmq-pass="$RMQ_ENCRYPTED"

# Encrypt and store Database password  
DB_ENCRYPTED=$(vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=$(echo -n "admin123" | base64))
vault kv put secret/vprofile db-pass="$DB_ENCRYPTED"

echo "✅ Encrypted secrets stored in Vault:"
echo "RMQ Password (encrypted): $RMQ_ENCRYPTED"
echo "DB Password (encrypted): $DB_ENCRYPTED"

# Verify storage
vault kv get secret/vprofile