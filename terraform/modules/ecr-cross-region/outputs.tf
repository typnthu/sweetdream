output "replication_configuration_id" {
  description = "ID of the ECR replication configuration"
  value       = var.enable_cross_region_replication ? aws_ecr_replication_configuration.cross_region[0].id : null
}

output "cross_region_repository_urls" {
  description = "Cross-region ECR repository URLs"
  value = var.enable_cross_region_replication ? {
    for name, repo in var.ecr_repositories : name => "${var.destination_account_id}.dkr.ecr.${var.destination_region}.amazonaws.com/${repo.name}"
  } : {}
}

output "ssm_parameter_name" {
  description = "SSM parameter name storing cross-region ECR info"
  value       = var.enable_cross_region_replication ? aws_ssm_parameter.cross_region_ecr_info[0].name : null
}