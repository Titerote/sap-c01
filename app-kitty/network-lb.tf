
resource "aws_lb" "employee" {
    name = "app-elb"
    internal = false
    load_balancer_type = "application"

    security_groups = [aws_security_group.allow_tls.id]
    subnets = [for subnet in [aws_subnet.kitty-public,aws_subnet.kitty-public-standby]: subnet.id]

    enable_cross_zone_load_balancing = true

    /** **
    subnet_mapping {
        subnet_id = aws_subnet.kitty-public.id
    }
    subnet_mapping {
        subnet_id = aws_subnet.kitty-public-standby.id
    }
    /** **/

    tags = {
        Name = "Employee App LB"
        Environment = "dev"
    }

}

/** **
resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.employee.arn
    port = "443"
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-2016-08"

    default_action {
        type = "forward"
        target_group_arn = 
    }
}
/** **/

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.employee.arn
    port = "80"
    protocol = "HTTP"

    /** **/
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.front-80.arn
    }
    /** **/
}

resource "aws_lb_target_group" "front-80" {
    name = "app-target-group-2"
    port = 80
    protocol = "HTTP"

    vpc_id = aws_vpc.kitty-app.id
}

resource "aws_lb_target_group_attachment" "node01" {
    target_group_arn = aws_lb_target_group.front-80.arn
    target_id = aws_instance.employee-app.id
    port = 80
}

resource "aws_lb_target_group_attachment" "node02" {
    target_group_arn = aws_lb_target_group.front-80.arn
    target_id = aws_instance.employee-app-standby.id
    port = 80
}

resource "aws_launch_template" "employee-app" {
    name = "app-launch-template"
    description = "A web server for the employee directory application"
    default_version = "1"

    image_id = data.aws_ami.amazon-linux-2.id
    instance_type = local.instance_type

    key_name = aws_key_pair.tite.key_name

    network_interfaces {
        associate_public_ip_address = true
        security_groups = [aws_security_group.allow_tls.id]
    }

    user_data = base64encode(data.template_cloudinit_config.config.rendered)

    iam_instance_profile {
        name = "EC2S3DynamoDBFullAccess"
    }

}

resource "aws_autoscaling_group" "front" {
    name = "app-asg"
    min_size = 2
    max_size = 4
    desired_capacity = 2

    vpc_zone_identifier = [aws_subnet.kitty-public.id, aws_subnet.kitty-public-standby.id]

    launch_template {
        id = aws_launch_template.employee-app.id
        version = "$Latest"
    }

    target_group_arns = [aws_lb_target_group.front-80.arn]
    health_check_type = "ELB"
}

resource "aws_autoscaling_policy" "cpu" {
    autoscaling_group_name = aws_autoscaling_group.front.name
    name = "CPU Utilization"

    policy_type            = "TargetTrackingScaling"
    /** **
    predictive_scaling_configuration {
        metric_specification {
            target_value = 10
            predefined_load_metric_specification {
                predefined_metric_type = "ASGTotalCPUUtilization"
                resource_label         = "testLabel"
            }
            customized_scaling_metric_specification {
                metric_data_queries {
                id = "scaling"
                metric_stat {
                    metric {
                    metric_name = "CPUUtilization"
                    namespace   = "AWS/EC2"
                    dimensions {
                        name  = "AutoScalingGroupName"
                        value = aws_autoscaling_group.front.name
                    }
                    }
                    stat = "Average"
                }
                }
            }
        }
    }
    /** **/
    target_tracking_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 60
        # disable_scale_in = false
    }
    estimated_instance_warmup = 300
    # cooldown = 300

}