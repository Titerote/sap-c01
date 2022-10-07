
# From: https://explore.skillbuilder.aws/learn/course/1851/play/45289/aws-technical-essentials-104;lp=1044

resource "aws_iam_role" "example" {
  name                = "EC2S3DynamoDBFullAccess"
  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)
  # managed_policy_arns = [aws_iam_policy.policy_one.arn, aws_iam_policy.policy_two.arn]
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
}

/** **/
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
/** **/
