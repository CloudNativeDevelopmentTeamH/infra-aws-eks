# Assume Role for Service Account (IRSA)
data "aws_iam_policy_document" "ecr_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

# IAM Role for Service Account (IRSA)
resource "aws_iam_role" "ecr_access_role" {
  name               = "eks-auth-ecr-access-role"
  assume_role_policy = data.aws_iam_policy_document.ecr_assume_role.json
}

# IAM Policy for ECR read access
resource "aws_iam_policy" "ecr_read_policy" {
  name        = "eks-ecr-read-policy"
  description = "Policy for EKS pods to pull images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach ECR read policy to the role
resource "aws_iam_role_policy_attachment" "ecr_access_attachment" {
  policy_arn = aws_iam_policy.ecr_read_policy.arn
  role       = aws_iam_role.ecr_access_role.name
}

# Kubernetes Service Account
resource "kubernetes_service_account_v1" "eks_service_account" {
  metadata {
    name      = "eks-service-account"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ecr_access_role.arn
    }
  }
}