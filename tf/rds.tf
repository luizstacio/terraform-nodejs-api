#
# TO DO: Complete remove password from terraform state
# https://github.com/rhythmictech/terraform-aws-secure-password
#
resource "random_password" "password" {
  length = 16
  special = false
}

resource "random_uuid" "db_identifier" {
}

resource "aws_db_instance" "default" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "postgres"
  engine_version          = "12.5"
  instance_class          = var.db_instance
  name                    = var.db_name
  identifier              = "${var.db_name}-${random_uuid.db_identifier.result}"
  username                = var.db_name
  password                = random_password.password.result
  skip_final_snapshot     = true
  vpc_security_group_ids = [aws_security_group.rds_sgroup.id]
}

resource "aws_ssm_parameter" "db_ssm_database" {
  name        = "/${var.app}/${var.environment}/databaseUrl"
  type        = "String"
  value       = aws_db_instance.default.endpoint
  overwrite = true
  tags = var.tags
}

resource "aws_ssm_parameter" "db_ssm_secret" {
  name        = "/${var.app}/${var.environment}/databasePassword"
  type        = "SecureString"
  value       = random_password.password.result
  overwrite = true
  tags = var.tags
}

resource "aws_ssm_parameter" "db_ssm_username" {
  name        = "/${var.app}/${var.environment}/databaseUsername"
  type        = "String"
  value       = aws_db_instance.default.username
  overwrite = true
  tags = var.tags
}

resource "aws_ssm_parameter" "db_ssm_name" {
  name        = "/${var.app}/${var.environment}/databaseName"
  type        = "String"
  value       = aws_db_instance.default.username
  overwrite = true
  tags = var.tags
}
