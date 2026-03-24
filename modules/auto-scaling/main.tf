variable "project_name"       { type = string }
variable "environment"        { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "app_sg_id"          { type = string }
variable "target_group_arn"   { type = string }
variable "instance_type"      { type = string; default = "t3.medium" }
variable "ami_id"             { type = string }
variable "min_size"           { type = number; default = 2 }
variable "max_size"           { type = number; default = 10 }
variable "desired_capacity"   { type = number; default = 2 }
variable "key_name"           { type = string; default = "" }

locals { name = "${var.project_name}-${var.environment}" }

resource "aws_iam_role" "app" {
  name = "${local.name}-app-role"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }] })
}
resource "aws_iam_role_policy_attachment" "ssm"        { role = aws_iam_role.app.name; policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
resource "aws_iam_role_policy_attachment" "cloudwatch" { role = aws_iam_role.app.name; policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" }
resource "aws_iam_instance_profile" "app"              { name = "${local.name}-app-profile"; role = aws_iam_role.app.name }

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  iam_instance_profile { name = aws_iam_instance_profile.app.name }
  network_interfaces { associate_public_ip_address = false; security_groups = [var.app_sg_id] }
  monitoring { enabled = true }
  metadata_options { http_endpoint = "enabled"; http_tokens = "required"; http_put_response_hop_limit = 1 }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs { volume_size = 30; volume_type = "gp3"; encrypted = true; delete_on_termination = true }
  }
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent amazon-ssm-agent docker
    systemctl enable --now amazon-ssm-agent docker
    usermod -aG docker ec2-user
  EOF
  )
  tag_specifications { resource_type = "instance"; tags = { Name = "${local.name}-app", Environment = var.environment } }
  lifecycle { create_before_destroy = true }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${local.name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.private_subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  launch_template { id = aws_launch_template.app.id; version = "$Latest" }
  instance_refresh { strategy = "Rolling"; preferences { min_healthy_percentage = 50; instance_warmup = 300 } }
  tag { key = "Name"; value = "${local.name}-asg"; propagate_at_launch = true }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 70.0
  }
}

output "asg_name"           { value = aws_autoscaling_group.app.name }
output "launch_template_id" { value = aws_launch_template.app.id }
