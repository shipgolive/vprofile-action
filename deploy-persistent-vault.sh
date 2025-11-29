#!/bin/bash
# Deploy Vault with persistent storage

echo "🔐 Deploying Vault with persistent gp2 storage..."

# Create namespace if it doesn't exist
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -

# Deploy Vault with persistent storage
kubectl apply -f vault-persistent-deployment.yml

# Wait for deployment
echo "⏳ Waiting for Vault to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/vault-persistent -n vault

# Get the new LoadBalancer URL
echo "🌐 Getting new Vault LoadBalancer URL..."
kubectl get svc vault-persistent-ui -n vault

echo "✅ Vault with persistent storage deployed!"
echo "📊 PVC Status:"
kubectl get pvc vault-storage -n vault

echo ""
echo "🔄 Update your startup script with the new Vault URL"
echo "🔐 All Vault configurations will now persist across restarts!"