#!/bin/bash
# Migrate to production Vault with persistent storage

echo "🔄 Migrating to production Vault with persistent storage..."

# Deploy production Vault
kubectl apply -f vault-production-deployment.yml

# Wait for deployment
echo "⏳ Waiting for production Vault to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/vault-production -n vault

# Get new LoadBalancer URL
echo "🌐 Getting new production Vault URL..."
NEW_VAULT_URL=$(kubectl get svc vault-production-ui -n vault -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "New Vault URL: http://$NEW_VAULT_URL:8200"

# Initialize Vault (first time only)
export VAULT_ADDR="http://$NEW_VAULT_URL:8200"
echo "🔐 Initializing production Vault..."
vault operator init -key-shares=1 -key-threshold=1 > vault-keys.txt

# Extract keys
UNSEAL_KEY=$(grep 'Unseal Key 1:' vault-keys.txt | awk '{print $NF}')
ROOT_TOKEN=$(grep 'Initial Root Token:' vault-keys.txt | awk '{print $NF}')

echo "Unseal Key: $UNSEAL_KEY"
echo "Root Token: $ROOT_TOKEN"

# Unseal Vault
vault operator unseal $UNSEAL_KEY

# Login and configure
export VAULT_TOKEN=$ROOT_TOKEN

# Enable engines
vault secrets enable transit
vault secrets enable -path=secret kv-v2

# Create encryption key
vault write -f transit/keys/vprofile-key

# Store encrypted passwords
vault kv put secret/vprofile \
  db-pass="vault:v1:i8aNOYhzjjoeKf2rDcGG556JQnfSFFqHSn88+VYG5QWqL6OD" \
  rmq-pass="vault:v1:8QOvVbf/OqH8pbqJn/IJArjzR0B58T1dKAqRr6RQWbneh/5f"

echo "✅ Production Vault configured!"
echo "📝 SAVE THESE CREDENTIALS:"
echo "Vault URL: http://$NEW_VAULT_URL:8200"
echo "Root Token: $ROOT_TOKEN"
echo "Unseal Key: $UNSEAL_KEY"