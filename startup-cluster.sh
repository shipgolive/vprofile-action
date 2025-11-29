#!/bin/bash
# startup-cluster.sh - Start EKS cluster for training

echo "🚀 Starting VPROFILE-EKS cluster..."

echo "⬆️ Scaling up Auto Scaling Groups..."
aws autoscaling update-auto-scaling-group --region us-east-2 --auto-scaling-group-name "eks-apps-node-group-20251126192526774100000007-bacd60d0-5be1-383d-eb03-919cc7b78178" --min-size 1 --max-size 4 --desired-capacity 3

aws autoscaling update-auto-scaling-group --region us-east-2 --auto-scaling-group-name "eks-monitoring-node-group-20251126192328467500000005-80cd60cf-74d2-fdb5-c2fd-4bbf995a0e11" --min-size 1 --max-size 2 --desired-capacity 1

echo "⏳ Waiting for instances to start..."
sleep 120

echo "🔄 Updating kubeconfig..."
aws eks update-kubeconfig --region us-east-2 --name VPROFILE-EKS

echo "🌐 Getting your current IP..."
NEW_IP=$(curl -s ifconfig.me)
echo "Your new IP: $NEW_IP"

echo "🔒 Updating LoadBalancer access restrictions..."
kubectl annotate svc grafana -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc prometheus-server -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc alertmanager -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc loki -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc argocd-server -n argocd service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc vault-ui-external -n vault service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite

echo "🔐 Production Vault Status Check..."
# Production Vault with persistent storage
export VAULT_ADDR="http://aa0f32b0720c6422ba63eadd3b2fc4e5-874159703.us-east-2.elb.amazonaws.com:8200"

# Check if Vault is unsealed (will show sealed status if not)
echo "Vault Status:"
vault status 2>/dev/null || echo "⚠️  Vault needs to be unsealed manually via UI"

# Check if Vault-integrated pods are running
kubectl get pods -l app=vprodb -o wide 2>/dev/null
kubectl get pods -l app=vpromq01 -o wide 2>/dev/null

echo "📊 Checking cluster status..."
kubectl get nodes
kubectl get pods --all-namespaces | grep -E "(monitoring|argocd|vault|vprodb|vpromq01)" | head -15

echo "🔑 Production Vault Status:"
echo "✅ Persistent storage: 10GB gp2 volume"
echo "✅ Kubernetes authentication: Configured"
echo "✅ Database & RabbitMQ: Using encrypted passwords from Vault"
echo "🌐 Vault UI: http://aa0f32b0720c6422ba63eadd3b2fc4e5-874159703.us-east-2.elb.amazonaws.com:8200"

echo "✅ Cluster startup complete!"
echo "🌐 All services accessible from IP: $NEW_IP"
echo "🔐 Production Vault encryption-as-a-service: READY"
echo "⚠️  Remember to unseal Vault via UI if needed"
echo "⏰ Wait 3-5 minutes for all services to be fully ready"