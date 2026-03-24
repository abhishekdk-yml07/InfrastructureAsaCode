variable "project_name"         { type = string }
variable "environment"          { type = string }
variable "vpc_id"               { type = string }
variable "database_subnet_ids"  { type = list(string) }
variable "db_subnet_group_name" { type = string }
variable "rds_sg_id"            { type = string }
variable "db_name"              { type = string; default = "appdb" }
variable "db_username"          { type = string; default = "dbadmin" }
variable "db_instance_class"    { type = string; default = "db.t3.medium" }
variable "db_engine_version"    { type = string; default = "15.4" }
variable "multi_az"             { type = bool; default = true }

locals { name = "${var.project_name}-${var.environment}" }

resource "random_password" "db" {
  length  = 32; special = true; override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name}/db-password"
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
}
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({ username = var.db_username, password = random_password.db.result, host = aws_db_instance.main.address, port = aws_db_instance.main.port, dbname = var.db_name })
}

resource "aws_db_parameter_group" "main" {
  name   = "${local.name}-pg15"
  family = "postgres15"
  parameter { name = "log_min_duration_statement"; value = "1000" }
  parameter { name = "shared_preload_libraries"; value = "pg_stat_statements" }
}

resource "aws_db_instance" "main" {
  identifier             = "${local.name}-postgres"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = random_password.db.result
  allocated_storage      = 100
  max_allocated_storage  = 1000
  storage_type           = "gp3"
  storage_encrypted      = true
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.rds_sg_id]
  parameter_group_name   = aws_db_parameter_group.main.name
  multi_az               = var.multi_az
  publicly_accessible    = false
  deletion_protection    = var.environment == "prod"
  backup_retention_period           = var.environment == "prod" ? 30 : 7
  backup_window                     = "03:00-04:00"
  maintenance_window                = "Mon:04:00-Mon:05:00"
  performance_insights_enabled      = true
  enabled_cloudwatch_logs_exports   = ["postgresql"]
  skip_final_snapshot               = var.environment != "prod"
  final_snapshot_identifier         = var.environment == "prod" ? "${local.name}-final-snapshot" : null
  tags = { Name = "${local.name}-postgres" }
}

output "db_endpoint"   { value = aws_db_instance.main.address; sensitive = true }
output "db_port"       { value = aws_db_instance.main.port }
output "db_secret_arn" { value = aws_secretsmanager_secret.db.arn }
