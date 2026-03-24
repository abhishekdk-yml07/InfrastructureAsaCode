output "vpc_id"           { value = module.vpc.vpc_id }
output "alb_dns_name"     { value = module.load_balancer.alb_dns_name }
output "asg_name"         { value = module.auto_scaling.asg_name }
output "rds_endpoint" {
  value     = module.rds.db_endpoint
  sensitive = true
}
output "s3_bucket_name"   { value = module.s3.bucket_name }
