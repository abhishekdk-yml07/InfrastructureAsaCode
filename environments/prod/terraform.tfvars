aws_region   = "us-east-1"
project_name = "myapp"
environment  = "prod"

vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnets   = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
enable_nat_gateway = true
single_nat_gateway = false

ami_id               = "ami-0c55b159cbfafe1f0"
instance_type        = "t3.large"
asg_min_size         = 3
asg_max_size         = 20
asg_desired_capacity = 3

db_instance_class = "db.r6g.large"
db_engine_version = "15.4"
db_multi_az       = true
