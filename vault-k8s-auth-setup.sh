#!/bin/bash
# Setup Kubernetes authentication for Vault

export VAULT_ADDR="http://aa0f32b0720c6422ba63eadd3b2fc4e5-874159703.us-east-2.elb.amazonaws.com:8200"
echo "Enter Vault root token:"
read -s VAULT_TOKEN
export VAULT_TOKEN

echo "🔐 Setting up Kubernetes authentication for Vault..."

# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://kubernetes.default.svc:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create role for vprofile pods
vault write auth/kubernetes/role/vprofile-role \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces=default \
    policies=vprofile-policy \
    ttl=24h

# Create service account
kubectl create serviceaccount vault-auth

echo "✅ Kubernetes auth configured for Vault integration"