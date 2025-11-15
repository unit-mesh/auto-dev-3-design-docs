# Bad Terraform file for testing Checkov

resource "aws_s3_bucket" "example" {
  bucket = "my-test-bucket"
  # Missing: encryption, versioning, logging
}

resource "aws_security_group" "example" {
  name        = "example"
  description = "Example security group"

  # Bad: allow all traffic from anywhere
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  # Missing: monitoring, encryption
}

