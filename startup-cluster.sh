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
kubectl annotate svc grafana-persistent -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc prometheus-server -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc alertmanager -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc loki -n monitoring service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc argocd-server -n argocd service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite
kubectl annotate svc vault-ui -n vault service.beta.kubernetes.io/aws-load-balancer-source-ranges="$NEW_IP/32" --overwrite

echo "📊 Checking cluster status..."
kubectl get nodes
kubectl get pods --all-namespaces | grep -E "(monitoring|argocd|vault)" | head -10

echo "✅ Cluster startup complete!"
echo "🌐 All services accessible from IP: $NEW_IP"
echo "⏰ Wait 3-5 minutes for all services to be fully ready"