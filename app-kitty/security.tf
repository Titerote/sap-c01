
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.kitty-app.id
#  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH from Management"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [data.aws_vpc.default.ipv6_cidr_block]
  }

  ingress {
    description      = "Port 80 inbound"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [data.aws_vpc.default.ipv6_cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    #cidr_blocks      = [data.aws_vpc.default.cidr_block]
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [data.aws_vpc.default.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
