# Self-signed SSL Certificate for testing
# WARNING: This is for development/testing only. Use proper domain-validated certificates in production.

# Generate private key
resource "tls_private_key" "self_signed" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create self-signed certificate
resource "tls_self_signed_cert" "self_signed" {
  private_key_pem = tls_private_key.self_signed.private_key_pem

  subject {
    common_name  = "*.${var.aws_region}.elb.amazonaws.com"
    organization = "Development Testing"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [
    "*.${var.aws_region}.elb.amazonaws.com",
    "*.elb.amazonaws.com"
  ]
}

# Import the self-signed certificate to ACM
resource "aws_acm_certificate" "self_signed" {
  private_key       = tls_private_key.self_signed.private_key_pem
  certificate_body  = tls_self_signed_cert.self_signed.cert_pem
  
  tags = {
    Name        = "${var.cluster_name}-self-signed-cert"
    Environment = "development"
    ManagedBy   = "OpenTofu"
  }

  lifecycle {
    create_before_destroy = true
  }
}
