#!/bin/bash
# Fix Vault policy for KV access

export VAULT_ADDR="http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"
export VAULT_TOKEN=root-token-123

echo "🔐 Updating Vault policy for KV access..."

# Update policy to include KV secrets access
vault policy write vprofile-policy - <<EOF
path "transit/encrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}
path "secret/data/vprofile" {
  capabilities = ["read"]
}
path "secret/metadata/vprofile" {
  capabilities = ["read"]
}
EOF

# Create new token with updated policy
NEW_TOKEN=$(vault token create -policy=vprofile-policy -ttl=24h -format=json | grep -o '"client_token":"[^"]*"' | cut -d'"' -f4)
echo "New token: $NEW_TOKEN"

# Update Kubernetes secret
kubectl delete secret vault-token
kubectl create secret generic vault-token --from-literal=VAULT_TOKEN=$NEW_TOKEN

echo "✅ Policy updated and new token created"