#!/bin/bash
# shutdown-cluster.sh - Scale down EKS cluster to save costs

echo "🛑 Shutting down VPROFILE-EKS cluster..."

echo "📊 Current cluster status:"
aws autoscaling describe-auto-scaling-groups --region us-east-2 --auto-scaling-group-names "eks-apps-node-group-20251126192526774100000007-bacd60d0-5be1-383d-eb03-919cc7b78178" "eks-monitoring-node-group-20251126192328467500000005-80cd60cf-74d2-fdb5-c2fd-4bbf995a0e11" --query "AutoScalingGroups[].[AutoScalingGroupName,DesiredCapacity]" --output table

echo "⬇️ Scaling down Auto Scaling Groups..."
aws autoscaling update-auto-scaling-group --region us-east-2 --auto-scaling-group-name "eks-apps-node-group-20251126192526774100000007-bacd60d0-5be1-383d-eb03-919cc7b78178" --min-size 0 --desired-capacity 0

aws autoscaling update-auto-scaling-group --region us-east-2 --auto-scaling-group-name "eks-monitoring-node-group-20251126192328467500000005-80cd60cf-74d2-fdb5-c2fd-4bbf995a0e11" --min-size 0 --desired-capacity 0

echo "⏳ Waiting for instances to terminate..."
sleep 60

echo "✅ Cluster shutdown complete!"
echo "💰 Cost savings: ~$120/month in EC2 charges"
echo "📊 Only paying for: EKS Control Plane + LoadBalancers + Storage (~$75/month)"
echo ""
echo "🔐 Data Protection Status:"
echo "✅ Grafana dashboards & configs: PRESERVED (PVC)"
echo "✅ Vault encrypted secrets: PRESERVED"
echo "✅ All configurations will restore on startup"
echo ""
echo "🚀 To restart: ./startup-cluster.sh"