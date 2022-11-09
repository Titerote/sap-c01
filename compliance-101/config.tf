

resource "aws_iam_role" "r" {
  name = "my-awsconfig-role"

  assume_role_policy  = data.aws_iam_policy_document.config_assume_role_policy.json # (not shown)
  /** **
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
  /** **/

  # managed_policy_arns = ["arn:aws:iam::aws:policy/aws-service-role/AWSConfigServiceRolePolicy"]
}

/** **/
data "aws_iam_policy_document" "config_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}
/** **/

resource "aws_iam_role_policy" "config-all" {
  name = "my-awsconfig-policy"
  role = aws_iam_role.r.id

  // TODO: This policy should be much more restrictive than *-*
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": "config:*",
          "Effect": "Allow",
          "Resource": "*"

      }
  ]
}
POLICY
}