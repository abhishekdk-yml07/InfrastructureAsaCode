aws_region   = "us-east-1"
project_name = "myapp"
environment  = "dev"

vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets    = ["10.1.11.0/24", "10.1.12.0/24"]
database_subnets   = ["10.1.21.0/24", "10.1.22.0/24"]
enable_nat_gateway = true
single_nat_gateway = true

ami_id               = "ami-0c55b159cbfafe1f0"
instance_type        = "t3.small"
asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 1

db_instance_class = "db.t3.medium"
db_engine_version = "15.4"
db_multi_az       = false
