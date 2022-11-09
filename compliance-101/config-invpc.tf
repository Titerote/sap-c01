
resource "aws_config_config_rule" "ec2-vpc" {
    name = "instance-vpc"

    source {
        owner = "AWS"
        # source_identifier = "REQUIRED_TAGS"
        source_identifier = "INSTANCES_IN_VPC"
    }

    depends_on = [ aws_config_configuration_recorder.ec2-vpc ]

}

resource "aws_config_configuration_recorder" "ec2-vpc" {
    name = "EC2-Instance-in-VPC"
    role_arn = aws_iam_role.r.arn
}

resource "aws_config_configuration_recorder_status" "ec2-vpc" {
    name = aws_config_configuration_recorder.ec2-vpc.name
    is_enabled = true
    depends_on = [aws_config_delivery_channel.ec2 ]
}

resource "aws_config_delivery_channel" "ec2" {
    name = "ec2-channel"
    s3_bucket_name = aws_s3_bucket.b.bucket
    depends_on = [ aws_config_configuration_recorder.ec2-vpc ]
}

resource "aws_s3_bucket" "b" {
    bucket = "awsconfig-example-38724"
}

resource "aws_iam_role_policy" "p2" {
  name = "awsconfig-example-two"
  role = aws_iam_role.r.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.b.arn}",
        "${aws_s3_bucket.b.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "ec2-get" {
  name = "my-awsconfig-policy-ec2get"
  role = aws_iam_role.r.id

  // TODO: This policy should be much more restrictive than *-*
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "ec2:*",
          "Effect": "Allow",
          "Resource": "*"

      }
  ]
}
POLICY
}