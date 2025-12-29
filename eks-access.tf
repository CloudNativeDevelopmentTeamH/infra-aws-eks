# User EKS Access
data "aws_caller_identity" "current" {}

resource "aws_eks_access_entry" "current_user_access" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "current_user_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

## Jump Server EKS Access
resource "aws_security_group_rule" "cluster_ingress_jumpserver_https" {
  description               = "Allow jumpserver to communicate with the cluster API Server"
  from_port                 = 443
  protocol                  = "tcp"
  security_group_id         = aws_security_group.security-group.id
  source_security_group_id  = aws_security_group.jump_server_sg.id
  to_port                   = 443
  type                      = "ingress"
}

resource "aws_eks_access_entry" "jump_server_access" {
  cluster_name      = aws_eks_cluster.cluster.name
  principal_arn     = aws_iam_role.jump_server_role.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "jump_server_admin" {
  cluster_name  = aws_eks_cluster.cluster.name
  principal_arn = aws_iam_role.jump_server_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}