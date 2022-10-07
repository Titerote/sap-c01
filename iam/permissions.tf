
resource "aws_iam_group_membership" "s3" {
    name = "S3-Support-Team-Members"
    users = [
        aws_iam_user.u1.name
    ]
    group = aws_iam_group.s3.name
}

resource "aws_iam_group_membership" "ec2" {
    name = "EC2-Support-Team-Members"
    users = [
        aws_iam_user.u2.name
    ]
    group = aws_iam_group.ec2.name
}

resource "aws_iam_group_membership" "ec2-admin" {
    name = "EC2-Admin-Team-Members"
    users = [
        aws_iam_user.u3.name
    ]
    group = aws_iam_group.ec2-admin.name
}