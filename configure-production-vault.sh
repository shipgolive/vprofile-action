#!/bin/bash
# Complete production Vault configuration with Kubernetes integration

export VAULT_ADDR="http://a366415017511462d974e014cdcec956-1263281851.us-east-2.elb.amazonaws.com:8200"
# Replace with your actual root token
export VAULT_TOKEN="your-actual-root-token-here"

echo "🔐 Configuring production Vault with Kubernetes integration..."

# 1. Enable secrets engines
echo "Enabling secrets engines..."
vault secrets enable transit
vault secrets enable -path=secret kv-v2

# 2. Create encryption key
echo "Creating encryption key..."
vault write -f transit/keys/vprofile-key

# 3. Enable Kubernetes authentication
echo "Enabling Kubernetes auth..."
vault auth enable kubernetes

# 4. Configure Kubernetes auth method
echo "Configuring Kubernetes auth..."
kubectl create serviceaccount vault-auth --dry-run=client -o yaml | kubectl apply -f -

# Get Kubernetes cluster info
K8S_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')
K8S_CA_CERT=$(kubectl get secret $(kubectl get serviceaccount vault-auth -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.ca\.crt}' | base64 -d)
SA_JWT_TOKEN=$(kubectl get secret $(kubectl get serviceaccount vault-auth -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)

# Configure Kubernetes auth in Vault
vault write auth/kubernetes/config \
    token_reviewer_jwt="$SA_JWT_TOKEN" \
    kubernetes_host="$K8S_HOST" \
    kubernetes_ca_cert="$K8S_CA_CERT"

# 5. Create policy for vprofile pods
echo "Creating vprofile policy..."
vault policy write vprofile-policy - <<EOF
# Transit permissions
path "transit/encrypt/vprofile-key" {
  capabilities = ["update"]
}
path "transit/decrypt/vprofile-key" {
  capabilities = ["update"]
}

# KV permissions
path "secret/data/vprofile" {
  capabilities = ["read"]
}
path "secret/metadata/vprofile" {
  capabilities = ["read"]
}
EOF

# 6. Create Kubernetes role
echo "Creating Kubernetes role..."
vault write auth/kubernetes/role/vprofile-role \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=default \
    policies=vprofile-policy \
    ttl=24h

# 7. Store encrypted passwords
echo "Storing encrypted passwords..."
vault kv put secret/vprofile \
  db-pass="vault:v1:i8aNOYhzjjoeKf2rDcGG556JQnfSFFqHSn88+VYG5QWqL6OD" \
  rmq-pass="vault:v1:8QOvVbf/OqH8pbqJn/IJArjzR0B58T1dKAqRr6RQWbneh/5f"

# 8. Test configuration
echo "Testing configuration..."
vault kv get secret/vprofile
vault read transit/keys/vprofile-key

echo "✅ Production Vault configured successfully!"
echo "📋 Configuration summary:"
echo "- Transit engine: Enabled"
echo "- KV secrets: Enabled"
echo "- Kubernetes auth: Configured"
echo "- Service account: vault-auth"
echo "- Policy: vprofile-policy"
echo "- Role: vprofile-role"