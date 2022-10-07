
data "aws_availability_zone" "primary" {
    name = "us-east-1f"
}

data "aws_availability_zone" "secondary" {
    name = "us-east-1a"
}