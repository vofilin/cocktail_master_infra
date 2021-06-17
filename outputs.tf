output "db_address" {
  description = "Database endpoint"
  value       = aws_db_instance.database.address
}

output "ecs-private-ips" {
  description = "IP of the active EC2 instance"
  value       = data.aws_instances.ecs_instances_meta.public_ips
}
