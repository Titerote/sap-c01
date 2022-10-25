
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
    # public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDX2trsDQUUC11HriZRug1vFQzhLNFkkGbWlylLfRJqub7qhWA7AErr7uz6xweodyjnGTn4Q/xl6v/gIkqlgVSDw+ip7LaiYKOu/6kqd6Of/1Cb3pujpXDsrjXUx23df/6mFirv+QzVROyTI9+2nU1G7kUolA6Tk5feDuWlXF3UmZ/zJSHfSPL8tf6KOapbngtQrXlm+xQbT293grMhJFpeVBF+57UPgGOG7K6gk01l8xcoHC9Uqn50Hl9/7mPWXSOSV+tWjEyZ63rrSF8dLRQ9qtsyfo41vIyR72c0NNyIdT4qbhE0hhKbStX3ZOtQeFfUxz0WU4TSbaXuwWANd0ks7Wujg4LdKwzSqYyvKA1AHAa+jlLU1uv7hHVPA6cFg3fJ7zik4ZD/vOR3S2awPyeuZyMBDSFvekUoYydYMsKTiwaQB7lE4RY2kuh5hN9SP42U19X/2tVTz2Am09CyZZFoGJfARpj9sAiRXVFarPolS59qMxfJuq1oCwLoA8/KLFt9+zNp8lq0EPPW4FkWI4V6/kriXwhdfPxZIf0BGnSzSWHKuRCcEvMNtr2o71Q4HX4vIZcAlWjpu44Zp9nthsH7+ukYVXT7n5cVKRfEqqLbxdkPjSF+RYSs4buK/tD1Di2YEbhijLbksTixcHoWfmR+DfwGLtFd/6RfqUrCOzlETw== /home/tite/id_rsa"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD8ltt0UJxa5WkRlsbZDpDkW0Dp1NpYjpXt0TKPeCAyCsShZCJLv7MthO+8cb1OaLDyySIF0YCtSSQHHMmN0JRh3ipMqPK0W5pvFT9wqXhP+ptCUrCAlWdAuZ4tsNJTQVVN0cKJSM07y1Wkbdu2rFIfZnzm0biZmE6YWBwkzT5A/SruJCRC/6e0looiWODq/Z4QF4+Sj8i5Wo72doik2AAEnk8vaHJ6U4Oep8/JWNM67KOmgHRz1aYYiKvlZ/8YCAim1hjfNuvH2LPSc4F/hIhrZM3Z2WL/Qvivn1gf+bxMZXMwzhHxGVc+SA6EL7UO29wNYqSDtrZPG2Ie1cqc/k5 tite@trankos-rsa"
}

resource "aws_iam_instance_profile" "kitty-app" {
  name = "EC2S3DynamoDBFullAccess"
#  role = aws_iam_role.role.name
  role = "EC2S3DynamoDBFullAccess"
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

locals {
  instance_type = "t2.small"
}

resource "aws_instance" "employee-app" {
    ami = data.aws_ami.amazon-linux-2.id
    instance_type = local.instance_type

    tags = {
        project = "SAP-C01"
        Name = "employee-webapp"
    }

    iam_instance_profile = "EC2S3DynamoDBFullAccess"
    key_name = aws_key_pair.tite.key_name

    # user_data = base64encode(templatefile(format("%s/vm-startup-sh.tmpl",path.module),{"ifdev": "eth0", "port": 1684, "host": "180.228.123.71" }))
    #user_data_base64 = "${data.template_cloudinit_config.config.rendered}"
    user_data_base64 = base64encode(data.template_cloudinit_config.config.rendered)
    user_data_replace_on_change = true

    /** **
    associate_public_ip_address = true
    vpc_security_group_ids = [aws_security_group.allow_tls.id]
    /** **/
    network_interface {
        network_interface_id = aws_network_interface.vmnic.id
        device_index = 0
    }
    /** **/

    depends_on = [aws_iam_instance_profile.kitty-app]
}

resource "aws_eip" "eployee-app-pip" {
  # vpc = true
  instance = aws_instance.employee-app.id

  depends_on = [
    aws_internet_gateway.gw
  ]
}

resource "aws_instance" "employee-app-standby" {
    ami = data.aws_ami.amazon-linux-2.id
    instance_type = local.instance_type

    tags = {
        project = "SAP-C01"
        Name = "employee-webapp-standby"
    }

    iam_instance_profile = "EC2S3DynamoDBFullAccess"
    key_name = aws_key_pair.tite.key_name

    user_data_replace_on_change = true
    user_data_base64 = base64encode(data.template_cloudinit_config.config.rendered)

    # associate_public_ip_address = true
    #vpc_security_group_ids = [aws_security_group.allow_tls.id]
    #security_groups = ["allow_tls"]
    /** **/
    network_interface {
        network_interface_id = aws_network_interface.vmnic-standby.id
        device_index = 0
    }
    /** **/

    depends_on = [aws_iam_instance_profile.kitty-app]
}
    
/** **
output "user_data" {
  value = "${data.template_cloudinit_config.config.rendered}"
}
/** **/

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
        #passwd: $6$DKswlKWQJI/0Bljw$Xo.nyowNH7V5efU74Ic5mVj7eejlGk5Ywk3tbAC0QdrQ/MZivKUm8cWZbvrJXWjnbzo.gQhQcisNjau5Iu9hg/
        #passwd: "$6$kW4vfBM9kGgq4hr$TFtHW7.3jOECR9UCBuw9NrdSMJETzSVoNQGcVv2y.RqRUzWDEtYhYRkGvIpB6ml1fh/fZEVIgKbSXI9L1B6xF."
        #ssh-authorized-keys: 
        #  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD8ltt0UJxa5WkRlsbZDpDkW0Dp1NpYjpXt0TKPeCAyCsShZCJLv7MthO+8cb1OaLDyySIF0YCtSSQHHMmN0JRh3ipMqPK0W5pvFT9wqXhP+ptCUrCAlWdAuZ4tsNJTQVVN0cKJSM07y1Wkbdu2rFIfZnzm0biZmE6YWBwkzT5A/SruJCRC/6e0looiWODq/Z4QF4+Sj8i5Wo72doik2AAEnk8vaHJ6U4Oep8/JWNM67KOmgHRz1aYYiKvlZ/8YCAim1hjfNuvH2LPSc4F/hIhrZM3Z2WL/Qvivn1gf+bxMZXMwzhHxGVc+SA6EL7UO29wNYqSDtrZPG2Ie1cqc/k5 tite@trankos-rsa
        # hashed_passwd: "$6$kW4vfBM9kGgq4hr$TFtHW7.3jOECR9UCBuw9NrdSMJETzSVoNQGcVv2y.RqRUzWDEtYhYRkGvIpB6ml1fh/fZEVIgKbSXI9L1B6xF."
    content      = <<-EOT
    users:
      - default
      - name: ec2-user
        ssh-authorized-keys: 
          - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD8ltt0UJxa5WkRlsbZDpDkW0Dp1NpYjpXt0TKPeCAyCsShZCJLv7MthO+8cb1OaLDyySIF0YCtSSQHHMmN0JRh3ipMqPK0W5pvFT9wqXhP+ptCUrCAlWdAuZ4tsNJTQVVN0cKJSM07y1Wkbdu2rFIfZnzm0biZmE6YWBwkzT5A/SruJCRC/6e0looiWODq/Z4QF4+Sj8i5Wo72doik2AAEnk8vaHJ6U4Oep8/JWNM67KOmgHRz1aYYiKvlZ/8YCAim1hjfNuvH2LPSc4F/hIhrZM3Z2WL/Qvivn1gf+bxMZXMwzhHxGVc+SA6EL7UO29wNYqSDtrZPG2Ie1cqc/k5 tite@trankos-rsa
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
      - name: tite
        hashed_passwd: $6$DKswlKWQJI/0Bljw$Xo.nyowNH7V5efU74Ic5mVj7eejlGk5Ywk3tbAC0QdrQ/MZivKUm8cWZbvrJXWjnbzo.gQhQcisNjau5Iu9hg/
        lock_passwd: false
        ssh_pwauth: True
        chpasswd: { expire: False }
        groups: users, admin
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
    runcmd:
      - [ "/tmp/cloud-init-start.sh" ]
    write_files:
      - path: /tmp/cloud-init-start.sh
        owner: root:root
        permissions: '0755'
        content: |
            ${indent(8,data.template_file.script.rendered)}
    ssh_pwauth: True
    EOT
  }

  /** **
  part {
    # content_type = "text/x-shellscript"
    content_type = "text/cloud-config"
    filename     = "cloud-init-start.sh"
    content      = <<-EOT
    EOT
  }

  part {
    content_type = "text/x-shellscript"
    content      = "ffbaz"
  }
  /** **/
}
