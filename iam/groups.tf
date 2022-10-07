
resource "aws_iam_group" "ec2-admin" {
    name = "EC2-Admin"
}

resource "aws_iam_group_policy" "ec2-admin" {
    name = "EC2_Admin_by_Tite"
    group = aws_iam_group.ec2-admin.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "cloudwatch:DescribeAlarms",
            ]
            Effect = "Allow"
            Resource = "*"
        }]
    })
}

resource "aws_iam_group" "ec2" {
    name = "EC2-Support"
}

resource "aws_iam_group_policy_attachment" "ec2" {
    group = aws_iam_group.ec2.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_group" "s3" {
    name = "S3-Support"
}

resource "aws_iam_group_policy_attachment" "s3" {
    group = aws_iam_group.s3.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_group" "ql-read" {
    name = "QLReadOnly"
}
