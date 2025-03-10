output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.main.endpoint
}

output "db_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "The username for the database"
  value       = aws_db_instance.main.username
}

output "db_security_group_id" {
  description = "The ID of the security group for the RDS instance"
  value       = aws_security_group.rds.id
} 