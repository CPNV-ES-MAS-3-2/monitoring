# --- Provider Variables ---
variable "region" {
  type        = string
  description = "The AWS region for deployment."
}

# --- Resource Naming ---
variable "project_name" {
  type        = string
  description = "The base name for the Auto Scaling Group and related resources."
}

# --- Compute Configuration ---
variable "ami_id" {
  type        = string
  description = "The AMI ID for the instances."
}

variable "instance_type" {
  type        = string
  description = "The EC2 instance type."
}

variable "key_name" {
  type        = string
  description = "The SSH key pair name for instance access."
}

# --- Network Configuration ---
variable "subnets" {
  type        = list(string)
  description = "List of Subnet IDs for the ASG."
}

variable "security_groups" {
  type        = list(string)
  description = "List of Security Group IDs for the instances."
}

# --- Scaling Limits ---
variable "min_size" {
  type        = number
  description = "Minimum number of instances in the fleet."
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in the fleet."
}

variable "instance_cooldown" {
  type        = number
  description = "Time in seconds, after a scaling activity completes before another can start."
}

variable "alarm_period" {
  type        = number
  description = "Period in seconds, over which the specified statistic is applied."
}

variable "health_check_grace_period" {
  type        = number
  description = "The time (in seconds) that ASG waits before checking an instance's health status." 
}

# --- DWH ---
variable "existing_dwh_node_01_instance_id" {
  description = "ID de l'instance Node 01 pour le monitoring réseau"
  type        = string
}

variable "existing_dwh_node_02_instance_id" {
  description = "ID de l'instance Node 02 à attacher à l'ASG"
  type        = string
}