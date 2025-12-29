data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "jump_server_role" {
  name = "${var.cluster_name}-jump-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jump_server_eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.jump_server_role.name
}

resource "aws_iam_role_policy_attachment" "jump_server_eks_describe" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.jump_server_role.name
}

resource "aws_iam_instance_profile" "jump_server_profile" {
  name = "${var.cluster_name}-jump-server-profile"
  role = aws_iam_role.jump_server_role.name
}

resource "aws_security_group" "jump_server_sg" {
  name        = "${var.cluster_name}-jump-server-sg"
  description = "Security group for jump server"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-jump-server-sg"
  }
}

resource "aws_instance" "jump_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.subnet[0].id
  vpc_security_group_ids      = [aws_security_group.jump_server_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jump_server_profile.name
  
  # Add your key pair name here
  # key_name = "your-key-pair-name"

  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system
              yum update -y
              
              # Install dependencies
              yum install -y curl unzip
              
              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/
              
              # Install helm
              curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
              
              # Configure kubectl for ec2-user
              su - ec2-user -c "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
              
              # Verify kubectl is working
              su - ec2-user -c "kubectl get nodes" > /tmp/kubectl-test.log 2>&1 || true
              
              # Create welcome message
              cat > /etc/motd <<'MOTD'
              ================================
              EKS Jump Server Ready!
              ================================
              kubectl is already configured!
              
              Try these commands:
              kubectl get nodes
              kubectl cluster-info
              kubectl get pods --all-namespaces
              ================================
              MOTD
              EOF

  depends_on = [
    aws_eks_cluster.cluster,
    aws_eks_node_group.group
  ]

  tags = {
    Name = "${var.cluster_name}-jump-server"
  }
}