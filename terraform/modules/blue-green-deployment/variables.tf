variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_services" {
  description = "Map of ECS services to configure blue-green deployment for"
  type = map(object({
    service_name      = string
    target_group_name = string
  }))
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration name"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnceBlueGreen"
  validation {
    condition = contains([
      "CodeDeployDefault.ECSAllAtOnceBlueGreen",
      "CodeDeployDefault.ECSLinear10PercentEvery1Minutes",
      "CodeDeployDefault.ECSLinear10PercentEvery3Minutes",
      "CodeDeployDefault.ECSCanary10Percent5Minutes",
      "CodeDeployDefault.ECSCanary10Percent15Minutes"
    ], var.deployment_config_name)
    error_message = "Invalid deployment configuration name."
  }
}

variable "termination_wait_time" {
  description = "Time to wait before terminating blue instances (in minutes)"
  type        = number
  default     = 5
}

variable "enable_alarm_rollback" {
  description = "Enable automatic rollback based on CloudWatch alarms"
  type        = bool
  default     = false
}

variable "rollback_alarms" {
  description = "List of CloudWatch alarm names for automatic rollback"
  type        = list(string)
  default     = []
}

variable "create_artifacts_bucket" {
  description = "Whether to create S3 bucket for CodeDeploy artifacts"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_notifications" {
  description = "Enable SNS notifications for deployments"
  type        = bool
  default     = false
}

variable "notification_email" {
  description = "Email address for deployment notifications"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}