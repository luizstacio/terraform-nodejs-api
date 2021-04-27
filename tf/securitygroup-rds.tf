resource "aws_security_group" "rds_sgroup" {
  name        = "${var.app}-${var.environment}-rds"
  description = "Limit connections to rds"
  vpc_id      = var.vpc_id

  tags = var.tags
}

# Rules for the TASK (Targets the LB's IPs)
resource "aws_security_group_rule" "rds_task_ingress_rule" {
  description = "Only allow connections from the ECS"
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  source_security_group_id = aws_security_group.nsg_task.id

  security_group_id = aws_security_group.rds_sgroup.id
}

resource "aws_security_group_rule" "rds_task_egress_rule" {
  description = "Allows task to establish connections to all resources"
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.rds_sgroup.id
}