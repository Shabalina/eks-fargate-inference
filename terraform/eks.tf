# 1. IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "cell-dino-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 2. EKS Control Plane
resource "aws_eks_cluster" "main" {
  name     = "cell-dino-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# 3. IAM Role for Fargate Pod Execution
resource "aws_iam_role" "fargate_pod_role" {
  name = "cell-dino-fargate-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_role.name
}

# 4. Fargate Profile targeting a specific Kubernetes namespace
resource "aws_eks_fargate_profile" "inference_profile" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "cell-dino-inference-profile"
  pod_execution_role_arn = aws_iam_role.fargate_pod_role.arn

  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  selector {
    namespace = "cell-dino-inference"
    labels = {
      app = "cell-dino"
    }
  }

  # Configures Fargate Spot capacity provider to claim a 70% discount
  tags = {
    "eks-fargate-capacity-type" = "spot"
  }

  depends_on = [aws_iam_role_policy_attachment.fargate_pod_execution]
}

resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "coredns"
  pod_execution_role_arn = aws_iam_role.fargate_pod_role.arn
  subnet_ids             = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  selector {
    namespace = "kube-system"
    # Keeping labels empty allows it to capture all pods in this namespace (like CoreDNS)
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # Pass custom configurations to automatically adapt CoreDNS for Fargate deployment
  configuration_values = jsonencode({
    computeType = "Fargate"
  })

  # Ensure the Fargate profiles are online before provisioning the add-on
  depends_on = [
    aws_eks_fargate_profile.kube_system
  ]
}

resource "aws_eks_access_entry" "console_user" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = "arn:aws:iam::${var.root_user_id}:root" # Grants access back to your account identities
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "console_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${var.root_user_id}:root"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.console_user]
}

resource "aws_eks_access_entry" "developer_user" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = "arn:aws:iam::${var.root_user_id}:user/awsadmin"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "developer_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::${var.root_user_id}:user/awsadmin"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.developer_user]
}