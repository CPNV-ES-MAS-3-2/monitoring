provider "aws" {
  region = var.region
}
# --- Enable Detailed Monitoring for DWH nodes ---
resource "null_resource" "enable_detailed_monitoring" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 monitor-instances --instance-ids ${var.existing_dwh_node_01_instance_id} ${var.existing_dwh_node_02_instance_id} --region ${var.region}
    EOT
  }

  triggers = {
    node_01 = var.existing_dwh_node_01_instance_id
    node_02 = var.existing_dwh_node_02_instance_id
  }
}

# --- Launch Template ---
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_groups

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "mas32-stage-${var.project_name}-node"
    }
  }
}

# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.subnets
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.instance_cooldown
}

# --- Attach Existing DWH Nodes to ASG ---
resource "null_resource" "attach_node_01_to_asg" {
  provisioner "local-exec" {
    command = "aws autoscaling attach-instances --instance-ids ${var.existing_dwh_node_01_instance_id} --auto-scaling-group-name ${aws_autoscaling_group.app_asg.name} --region ${var.region}"
  }

  triggers = {
    instance_id = var.existing_dwh_node_01_instance_id
    asg_name    = aws_autoscaling_group.app_asg.name
  }

  depends_on = [aws_autoscaling_group.app_asg]
}

resource "null_resource" "attach_node_02_to_asg" {
  provisioner "local-exec" {
    command = "aws autoscaling attach-instances --instance-ids ${var.existing_dwh_node_02_instance_id} --auto-scaling-group-name ${aws_autoscaling_group.app_asg.name} --region ${var.region}"
  }

  triggers = {
    instance_id = var.existing_dwh_node_02_instance_id
    asg_name    = aws_autoscaling_group.app_asg.name
  }

  depends_on = [aws_autoscaling_group.app_asg]
}

# --- Scaling Policies ---
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.instance_cooldown
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.instance_cooldown
}

# --- CloudWatch Alarms ---
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-High-CPU-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-Low-CPU-Alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}