#!/bin/bash
# vault-transit-setup.sh - Configure Vault Transit Engine for Encryption

echo "🔐 Setting up Vault Transit Engine for Encryption..."

# Get Vault pod name
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[0].metadata.name}')
echo "Using Vault pod: $VAULT_POD"

# Initialize and unseal Vault (if needed)
echo "🔓 Checking Vault status..."
kubectl exec -n vault $VAULT_POD -- vault status

# Enable Transit secrets engine
echo "🚀 Enabling Transit secrets engine..."
kubectl exec -n vault $VAULT_POD -- vault secrets enable transit

# Create encryption key
echo "🔑 Creating encryption key 'vprofile-key'..."
kubectl exec -n vault $VAULT_POD -- vault write -f transit/keys/vprofile-key

# Create policy for transit operations
echo "📋 Creating transit policy..."
kubectl exec -n vault $VAULT_POD -- vault policy write transit-policy - <<EOF
path "transit/encrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/datakey/plaintext/vprofile-key" {
  capabilities = ["update"]
}
EOF

# Create token with transit policy
echo "🎫 Creating token for transit operations..."
TRANSIT_TOKEN=$(kubectl exec -n vault $VAULT_POD -- vault token create -policy=transit-policy -format=json | jq -r '.auth.client_token')
echo "Transit Token: $TRANSIT_TOKEN"

echo "✅ Transit engine setup complete!"
echo ""
echo "🔐 Testing encryption/decryption:"

# Test encryption
echo "📝 Encrypting sample data..."
ENCRYPTED=$(kubectl exec -n vault $VAULT_POD -- vault write -field=ciphertext transit/encrypt/vprofile-key plaintext=$(echo -n "Hello Vault Transit!" | base64))
echo "Encrypted: $ENCRYPTED"

# Test decryption
echo "🔓 Decrypting data..."
DECRYPTED=$(kubectl exec -n vault $VAULT_POD -- vault write -field=plaintext transit/decrypt/vprofile-key ciphertext=$ENCRYPTED)
echo "Decrypted: $(echo $DECRYPTED | base64 -d)"

echo ""
echo "🌐 Vault UI: Access via LoadBalancer to manage keys"
echo "🔑 Use token: $TRANSIT_TOKEN for API calls"