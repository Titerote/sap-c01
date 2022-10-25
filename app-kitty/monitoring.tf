
resource "aws_cloudwatch_dashboard" "employee" {
    dashboard_name = "Employee-Monitor"

    dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "${aws_instance.employee-app.id}"
          ],
          [
            "AWS/EC2",
            "CPUUtilization",
            "InstanceId",
            "${aws_instance.employee-app-standby.id}"
          ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${data.aws_availability_zone.primary.region}",
        "title": "EC2 Instance CPU"
      }
    },
    {
      "type": "text",
      "x": 0,
      "y": 7,
      "width": 3,
      "height": 3,
      "properties": {
        "markdown": "Hello world ${data.aws_availability_zone.primary.region}"
      }
    }
  ]
}
EOF

}

resource "aws_cloudwatch_metric_alarm" "cpu" {
    alarm_name = "cpu-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors my ec2 cpu utilization"
    insufficient_data_actions = []

    alarm_actions = [aws_sns_topic.support.arn]
    ok_actions = [aws_sns_topic.support.arn]
}

resource "aws_sns_topic" "support" {
    name = "Employee-App-CPU"
}

resource "aws_sns_topic_subscription" "smtp" {
    topic_arn = aws_sns_topic.support.arn
    protocol = "email"
    endpoint = "jmoragrega@santander.us"
}