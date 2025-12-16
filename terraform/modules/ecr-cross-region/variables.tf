variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "enable_cross_region_replication" {
  description = "Enable ECR cross-region replication"
  type        = bool
  default     = false
}

variable "enable_cross_region_access" {
  description = "Enable cross-region ECR access policies"
  type        = bool
  default     = false
}

variable "source_region" {
  description = "Source AWS region"
  type        = string
}

variable "destination_region" {
  description = "Destination AWS region for replication"
  type        = string
}

variable "destination_account_id" {
  description = "Destination AWS account ID"
  type        = string
}

variable "ecr_repositories" {
  description = "Map of ECR repositories"
  type = map(object({
    name           = string
    arn            = string
    repository_url = string
  }))
  default = {}
}

variable "repository_filters" {
  description = "Repository filters for replication"
  type = list(object({
    filter      = string
    filter_type = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}