
resource "aws_iam_user" "u1" {
    name = "user-1"
    tags = {
        project = "sap-c01"
    }
}

resource "aws_iam_user_login_profile" "u1" {
    user = aws_iam_user.u1.name
    password_reset_required = false
}

resource "aws_iam_user" "u2" {
    name = "user-2"
    tags = {
        project = "sap-c01"
    }
}

resource "aws_iam_user_login_profile" "u2" {
    user = aws_iam_user.u2.name
    password_reset_required = false
}

resource "aws_iam_user" "u3" {
    name = "user-3"
    tags = {
        project = "sap-c01"
    }
}

resource "aws_iam_user_login_profile" "u3" {
    user = aws_iam_user.u3.name
    password_reset_required = false
}

output "credentials" {
    value = {
        "user-1" = aws_iam_user_login_profile.u1.password,
        "user-2" = aws_iam_user_login_profile.u2.password,
        "user-3" = aws_iam_user_login_profile.u3.password,
    }
}