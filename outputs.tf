output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "rds_instance_id" {
  value = module.rds.db_instance_id
}
