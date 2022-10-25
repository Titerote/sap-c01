

resource "aws_s3_bucket" "app-kitty" {
    bucket = "employee-photo-bucket-at-234239"

    tags = {
        Name = "Employee Photos"
        Environment = "Dev"
    }
}

resource "aws_s3_bucket_policy" "allow_s3_read" {
    bucket = aws_s3_bucket.app-kitty.id
    policy = data.aws_iam_policy_document.allow_s3_read.json
}

data "aws_iam_policy_document" "allow_s3_read" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::812529097763:role/EC2S3DynamoDBFullAccess"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.app-kitty.arn,
      "${aws_s3_bucket.app-kitty.arn}/*",
    ]
  }
}

/** **
resource "aws_db_instance" "employee-db" {
    db_name = "employee_database"
    engine = "mysql"
    instance_class = "db.t2.micro"
    username = "admin"
    password = "admin123"

    allocated_storage = 20
    skip_final_snapshot = true
}
/** **/

resource "aws_dynamodb_table" "employee-db" {
    name = "Employees"
    hash_key = "id"

    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 5

    attribute {
        name = "id"
        type = "S"
    }

    tags = {
        Name = "employee-database"
        Environment = "dev"
    }
}
/** **/