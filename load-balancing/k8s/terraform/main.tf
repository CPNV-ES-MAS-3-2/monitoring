provider "aws" {
  region = var.region
}

# --- Enable Detailed Monitoring for K8s Master ---
resource "null_resource" "enable_master_monitoring" {
  provisioner "local-exec" {
    command = "aws ec2 monitor-instances --instance-ids ${var.k8s_master_instance_id} --region ${var.region}"
  }

  triggers = {
    master_id = var.k8s_master_instance_id
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
}

# --- Attach Existing K8s Node to ASG ---
resource "null_resource" "attach_existing_node" {
  provisioner "local-exec" {
    command = "aws autoscaling attach-instances --instance-ids ${var.existing_k8s_node_id} --auto-scaling-group-name ${aws_autoscaling_group.app_asg.name} --region ${var.region}"
  }

  triggers = {
    instance_id = var.existing_k8s_node_id
    asg_name    = aws_autoscaling_group.app_asg.name
  }

  depends_on = [aws_autoscaling_group.app_asg]
}

# --- Force Enable Monitoring for the Node ---
resource "null_resource" "enable_node_monitoring" {
  provisioner "local-exec" {
    # This command specifically targets the node ID
    command = "aws ec2 monitor-instances --instance-ids ${var.existing_k8s_node_id} --region ${var.region}"
  }

  triggers = {
    instance_id = var.existing_k8s_node_id
  }

  # Ensure this runs even if the attachment was already done
  depends_on = [null_resource.attach_existing_node]
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
resource "aws_cloudwatch_metric_alarm" "master_network_high" {
  alarm_name          = "${var.project_name}-Master-Network-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.network_in_threshold

  dimensions = {
    InstanceId = var.k8s_master_instance_id
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

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