
resource "aws_config_config_rule" "ec2-type" {
    name = "instance-type"

    source {
        owner = "AWS"
        # source_identifier = "REQUIRED_TAGS"
        source_identifier = "DESIRED_INSTANCE_TYPE"
    }

    ### Scope can be: Resources, Tags or All-Changes
    scope {
        compliance_resource_types = ["AWS::EC2::Instance"]
        # tag_key = "instanceType"
        # tag_value = "t2.micro"
    }
    
    input_parameters = "{ \"instanceType\": \"t2.micro\" }"

    depends_on = [ aws_config_configuration_recorder.ec2-vpc ]

}

/** **
resource "aws_config_configuration_recorder" "ec2-type" {
    name = "EC2-Instance-Type"
    role_arn = aws_iam_role.r.arn
}
/** **/
