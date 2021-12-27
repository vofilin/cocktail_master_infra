output "db_address" {
  description = "Database endpoint"
  value       = aws_db_instance.database.address
}

output "ecs_public_ips" {
  description = "IP of the active EC2 instance"
  value       = data.aws_instances.ecs_instances_meta.public_ips
}

output "alb_address" {
  description = "ALB address"
  value       = aws_lb.cocktail_master.dns_name
}
