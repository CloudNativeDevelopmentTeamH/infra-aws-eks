# Get thumbprint for OIDC provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Create OIDC provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

# Create IAM role for EBS CSI Driver
data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect   = "Allow"
    actions  = ["sts:AssumeRoleWithWebIdentity"]
    
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

resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}

# EKS addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.29.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
}