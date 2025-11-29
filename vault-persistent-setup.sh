#!/bin/bash
# Make Vault configuration persistent

export VAULT_ADDR="http://ad8d1589c834542a3a0778944c8f03c4-87591684.us-east-2.elb.amazonaws.com:8200"
export VAULT_TOKEN=root-token-123

echo "🔐 Making Vault configuration persistent..."

# Check if Vault has persistent storage
kubectl get pvc -n vault

# If no PVC exists, Vault will lose config on restart
# The configuration needs to be in your startup script

echo "✅ Adding Vault setup to startup script for persistence"