variable "aws_region"   { type = string; default = "us-east-1" }
variable "project_name" { type = string }
variable "environment"  {
  type = string
  validation {
    condition     = contains(["dev","staging","prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}
variable "vpc_cidr"            { type = string; default = "10.0.0.0/16" }
variable "availability_zones"  { type = list(string) }
variable "public_subnets"      { type = list(string) }
variable "private_subnets"     { type = list(string) }
variable "database_subnets"    { type = list(string) }
variable "enable_nat_gateway"  { type = bool; default = true }
variable "single_nat_gateway"  { type = bool; default = false }
variable "certificate_arn"     { type = string; default = "" }
variable "instance_type"       { type = string; default = "t3.medium" }
variable "ami_id"              { type = string }
variable "asg_min_size"        { type = number; default = 2 }
variable "asg_max_size"        { type = number; default = 10 }
variable "asg_desired_capacity"{ type = number; default = 2 }
variable "db_name"             { type = string; default = "appdb" }
variable "db_username"         { type = string; default = "dbadmin"; sensitive = true }
variable "db_instance_class"   { type = string; default = "db.t3.medium" }
variable "db_engine_version"   { type = string; default = "15.4" }
variable "db_multi_az"         { type = bool; default = true }
