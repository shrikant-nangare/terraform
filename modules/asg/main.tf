# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for Auto Scaling Group (for CloudWatch metrics)
resource "aws_iam_role" "asg" {
  name = "${var.project_name}-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-asg-role"
    }
  )
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "asg_cloudwatch" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile for ASG instances
resource "aws_iam_instance_profile" "asg" {
  name = "${var.project_name}-asg-instance-profile"
  role = aws_iam_role.asg.name

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-asg-instance-profile"
    }
  )
}

# Launch Template for Public Subnet ASG
resource "aws_launch_template" "public" {
  name_prefix   = "${var.project_name}-public-asg-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = [var.public_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 6
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-linux -s
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-public-asg-instance"
        Type = "public"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-launch-template"
    }
  )
}

# Launch Template for Private Subnet ASG
resource "aws_launch_template" "private" {
  name_prefix   = "${var.project_name}-private-asg-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name != "" ? var.key_pair_name : null

  vpc_security_group_ids = [var.private_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 6
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-linux -s
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-private-asg-instance"
        Type = "private"
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-launch-template"
    }
  )
}

# Auto Scaling Group for Public Subnet
resource "aws_autoscaling_group" "public" {
  name                      = "${var.project_name}-public-asg"
  vpc_zone_identifier       = [var.public_subnet_id]
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.public.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-public-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Auto Scaling Group for Private Subnet
resource "aws_autoscaling_group" "private" {
  name                      = "${var.project_name}-private-asg"
  vpc_zone_identifier       = [var.private_subnet_id]
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.private.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-private-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# CloudWatch Alarm for CPU Utilization - Scale Up (Public)
resource "aws_cloudwatch_metric_alarm" "cpu_high_public" {
  alarm_name          = "${var.project_name}-public-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_target
  alarm_description   = "This metric monitors ec2 cpu utilization for scale up"
  alarm_actions       = [aws_autoscaling_policy.scale_up_public.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public.name
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-asg-cpu-high-alarm"
    }
  )
}

# CloudWatch Alarm for CPU Utilization - Scale Down (Public)
resource "aws_cloudwatch_metric_alarm" "cpu_low_public" {
  alarm_name          = "${var.project_name}-public-asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_target
  alarm_description   = "This metric monitors ec2 cpu utilization for scale down"
  alarm_actions       = [aws_autoscaling_policy.scale_down_public.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public.name
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-asg-cpu-low-alarm"
    }
  )
}

# Auto Scaling Policy - Scale Up (Public)
resource "aws_autoscaling_policy" "scale_up_public" {
  name                   = "${var.project_name}-public-asg-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.public.name
}

# Auto Scaling Policy - Scale Down (Public)
resource "aws_autoscaling_policy" "scale_down_public" {
  name                   = "${var.project_name}-public-asg-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.public.name
}

# CloudWatch Alarm for CPU Utilization - Scale Up (Private)
resource "aws_cloudwatch_metric_alarm" "cpu_high_private" {
  alarm_name          = "${var.project_name}-private-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_target
  alarm_description   = "This metric monitors ec2 cpu utilization for scale up"
  alarm_actions       = [aws_autoscaling_policy.scale_up_private.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.private.name
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-asg-cpu-high-alarm"
    }
  )
}

# CloudWatch Alarm for CPU Utilization - Scale Down (Private)
resource "aws_cloudwatch_metric_alarm" "cpu_low_private" {
  alarm_name          = "${var.project_name}-private-asg-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_target
  alarm_description   = "This metric monitors ec2 cpu utilization for scale down"
  alarm_actions       = [aws_autoscaling_policy.scale_down_private.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.private.name
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-asg-cpu-low-alarm"
    }
  )
}

# Auto Scaling Policy - Scale Up (Private)
resource "aws_autoscaling_policy" "scale_up_private" {
  name                   = "${var.project_name}-private-asg-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.private.name
}

# Auto Scaling Policy - Scale Down (Private)
resource "aws_autoscaling_policy" "scale_down_private" {
  name                   = "${var.project_name}-private-asg-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.private.name
}

