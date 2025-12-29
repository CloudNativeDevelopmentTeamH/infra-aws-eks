resource "aws_iam_role" "cluster-iam-role" {
  name = "${var.cluster_name}-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-iam-role.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster-iam-role.name
}

resource "aws_security_group" "security-group" {
  name        = "${var.cluster_name}-security-group"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}"
  }
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster-iam-role.arn

  vpc_config {
    security_group_ids = [aws_security_group.security-group.id]
    subnet_ids         = aws_subnet.subnet[*].id
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
  ]
}

resource "aws_security_group_rule" "cluster_ingress_jumpserver_https" {
  description              = "Allow jumpserver to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.security-group.id
  source_security_group_id = aws_security_group.jump_server_sg.id
  to_port                  = 443
  type                     = "ingress"

  depends_on = [aws_eks_cluster.cluster]
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

  depends_on = [aws_eks_access_entry.jump_server_access]
}