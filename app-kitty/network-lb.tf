
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