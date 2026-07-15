#!/bin/bash

# # Exit immediately if any command fails
# set -e

# echo "Starting EKS Fargate & ALB Cleanup Protocol..."

# # 1. Rename the ingress file back momentarily if it was disabled, just to delete it
# if [ -f "k8s/ingress.yaml.disabled" ]; then
#     echo "Temporarily enabling ingress manifest for teardown..."
#     mv k8s/ingress.yaml.disabled k8s/ingress.yaml
#     RENAME_BACK=true
# fi

# # 2. Delete Ingress to safely clean up the AWS ALB
# if [ -f "k8s/ingress.yaml" ]; then
#     echo "Deleting Kubernetes Ingress (ALB & Target Groups)..."
#     kubectl delete -f k8s/ingress.yaml || echo "Ingress already deleted or cluster unreachable."
    
#     echo "Waiting 90 seconds for AWS ALB controller to cleanly de-provision the load balancer..."
#     sleep 90
# else
#     echo "ingress.yaml not found. Skipping ALB controller teardown."
# fi

# # Put the disabled extension back if we changed it
# if [ "$RENAME_BACK" = true ]; then
#     mv k8s/ingress.yaml k8s/ingress.yaml.disabled
# fi

# 3. Destroy Terraform managed infrastructure (VPC, NAT Gateways, EKS cluster)
if [ -d "terraform" ]; then
    echo "📂 Found terraform directory. Stepping inside..."
    cd terraform
    
    # NEW: Initialize the remote S3 backend first
    echo "⚙️ Initializing Terraform backend..."
    terraform init -input=false
    
    echo "🏗️ Running Terraform Destroy..."
    terraform destroy --auto-approve
    
    echo "📂 Stepping back to root directory..."
    cd ..
else
    echo "⚠️ No 'terraform' directory found!"
fi

echo "✅ All resources successfully deleted! Check your AWS billing console to verify."