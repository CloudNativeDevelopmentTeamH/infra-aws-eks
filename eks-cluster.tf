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

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
  ]
}