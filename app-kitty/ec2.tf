
data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
#   values = ["amzn2-ami-hvm*"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "tite" {
    key_name = "tite-devbox"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDX2trsDQUUC11HriZRug1vFQzhLNFkkGbWlylLfRJqub7qhWA7AErr7uz6xweodyjnGTn4Q/xl6v/gIkqlgVSDw+ip7LaiYKOu/6kqd6Of/1Cb3pujpXDsrjXUx23df/6mFirv+QzVROyTI9+2nU1G7kUolA6Tk5feDuWlXF3UmZ/zJSHfSPL8tf6KOapbngtQrXlm+xQbT293grMhJFpeVBF+57UPgGOG7K6gk01l8xcoHC9Uqn50Hl9/7mPWXSOSV+tWjEyZ63rrSF8dLRQ9qtsyfo41vIyR72c0NNyIdT4qbhE0hhKbStX3ZOtQeFfUxz0WU4TSbaXuwWANd0ks7Wujg4LdKwzSqYyvKA1AHAa+jlLU1uv7hHVPA6cFg3fJ7zik4ZD/vOR3S2awPyeuZyMBDSFvekUoYydYMsKTiwaQB7lE4RY2kuh5hN9SP42U19X/2tVTz2Am09CyZZFoGJfARpj9sAiRXVFarPolS59qMxfJuq1oCwLoA8/KLFt9+zNp8lq0EPPW4FkWI4V6/kriXwhdfPxZIf0BGnSzSWHKuRCcEvMNtr2o71Q4HX4vIZcAlWjpu44Zp9nthsH7+ukYVXT7n5cVKRfEqqLbxdkPjSF+RYSs4buK/tD1Di2YEbhijLbksTixcHoWfmR+DfwGLtFd/6RfqUrCOzlETw== /home/tite/id_rsa"
}

resource "aws_iam_instance_profile" "kitty-app" {
  name = "EC2S3DynamoDBFullAccess"
#  role = aws_iam_role.role.name
  role = "EC2S3DynamoDBFullAccess"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.kitty-app.id

  ingress {
    description      = "SSH from Management"
    from_port        = 0
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = [data.aws_vpc.default.ipv6_cidr_block]
  }

  ingress {
    description      = "Port 80 inbound"
    from_port        = 0
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

resource "aws_eip" "vm1" {
  network_border_group = data.aws_availability_zone.primary.region
}

resource "aws_network_interface" "vmnic" {
    #subnet_id = data.aws_subnet.default.id
    subnet_id = aws_subnet.kitty-public.id
    security_groups = [aws_security_group.allow_tls.id]

    tags = {
        project = "SAP-C01"
    }

}

resource "aws_instance" "ub" {
    ami = data.aws_ami.amazon-linux-2.id
    instance_type = "t3.micro"

    tags = {
        project = "SAP-C01"
        Name = "employee-webapp"
    }

    iam_instance_profile = "EC2S3DynamoDBFullAccess"
    key_name = aws_key_pair.tite.key_name

    # user_data = base64encode(templatefile(format("%s/vm-startup-sh.tmpl",path.module),{"ifdev": "eth0", "port": 1684, "host": "180.228.123.71" }))
    #user_data_base64 = "${data.template_cloudinit_config.config.rendered}"
    user_data_base64 = base64encode(data.template_cloudinit_config.config.rendered)

    associate_public_ip_address = true
    /** **
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    /** **
    network_interface {
        network_interface_id = aws_network_interface.vmnic.id
        device_index = 0
    }
    /** **/

    depends_on = [aws_iam_instance_profile.kitty-app]
}

resource "aws_instance" "employee-app" {
    ami = data.aws_ami.amazon-linux-2.id
    instance_type = "t3.micro"

    tags = {
        project = "SAP-C01"
        Name = "employee-webapp-standby"
    }

    iam_instance_profile = "EC2S3DynamoDBFullAccess"
    key_name = aws_key_pair.tite.key_name

    #user_data = base64encode(templatefile(format("%s/vm-startup-sh.tmpl",path.module),{"ifdev": "eth0", "port": 1684, "host": "180.228.123.71" }))
    #user_data_base64 = "${data.template_cloudinit_config.config.rendered}"
    # user_data_base64 = base64encode(data.template_cloudinit_config.config.rendered)
    user_data      = <<-EOT
    users:
      - name: tite
        passwd: $6$DKswlKWQJI/0Bljw$Xo.nyowNH7V5efU74Ic5mVj7eejlGk5Ywk3tbAC0QdrQ/MZivKUm8cWZbvrJXWjnbzo.gQhQcisNjau5Iu9hg/
    EOT


    /** **/
    associate_public_ip_address = true
    #vpc_security_group_ids = [aws_security_group.allow_tls.id]
    #security_groups = ["allow_tls"]
    /** **
    network_interface {
        network_interface_id = aws_network_interface.vmnic-standby.id
        device_index = 0
    }
    /** **/

    depends_on = [aws_iam_instance_profile.kitty-app]
}
    
output "user_data" {
  value = "${data.template_cloudinit_config.config.rendered}"
}

resource "aws_network_interface" "vmnic-standby" {
    #subnet_id = data.aws_subnet.default.id
    subnet_id = aws_subnet.kitty-public-standby.id
    security_groups = [aws_security_group.allow_tls.id]

    tags = {
        project = "SAP-C01"
    }

}

# Render a part using a `template_file`
data "template_file" "script" {
  template = "${file("${path.module}/vm-startup-sh.tmpl")}"

  vars = {
    consul_address = "0.0.0.0"
  }
}

# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = <<-EOT
    users:
      - name: tite
        passwd: $6$DKswlKWQJI/0Bljw$Xo.nyowNH7V5efU74Ic5mVj7eejlGk5Ywk3tbAC0QdrQ/MZivKUm8cWZbvrJXWjnbzo.gQhQcisNjau5Iu9hg/
    EOT
  }

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.script.rendered}"
  }

  part {
    content_type = "text/x-shellscript"
    content      = "ffbaz"
  }
}
