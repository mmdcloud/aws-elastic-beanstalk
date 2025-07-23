output "eb_environment_url" {
  description = "Elastic Beanstalk environment URL"
  value       = aws_elastic_beanstalk_environment.prod_env.cname
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.production_db.endpoint
}

output "rds_connection_string" {
  description = "RDS connection string (without password)"
  value       = "postgresql://${var.db_username}@${aws_db_instance.production_db.endpoint}/${var.db_name}"
  sensitive   = true
}