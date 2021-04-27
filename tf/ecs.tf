#
#     Variables
#
variable "replicas" {
  description = "Number of replicas running"
  default = "1"
}

variable "ecs_autoscale_min_instances" {
  default = "1"
}

variable "ecs_autoscale_max_instances" {
  default = "5"
}

variable "logs_retention_in_days" {
  type        = number
  default     = 90
  description = "Specifies the number of days you want to retain log events"
}

#
# Create IAM
#
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app}-${var.environment}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = var.tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecsTaskPolicyDocument" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}

resource "aws_iam_policy" "ecsTaskPolicy" {
  name        = "policy-${var.app}-${var.environment}"
  policy      = data.aws_iam_policy_document.ecsTaskPolicyDocument.json
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.ecsTaskPolicy.arn
}

#
#     Resources
#
resource "aws_ecs_cluster" "app" {
  name = "${var.app}-${var.environment}"
  tags = var.tags
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = <<DEFINITION
    [
      {
        "name": "${var.app}",
        "image": "${aws_ecr_repository.app.name}",
        "essential": true,
        "portMappings": [
          {
            "protocol": "tcp",
            "containerPort": ${var.container_port},
            "hostPort": ${var.container_port}
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "secretOptions": null,
          "options": {
            "awslogs-group": "/fargate/service/${var.app}-${var.environment}",
            "awslogs-region": "${var.region}",
            "awslogs-stream-prefix": "ecs"
          }
        },
        "environment": [
          {
            "name": "PORT",
            "value": "${var.container_port}"
          },
          {
            "name": "PRODUCT",
            "value": "${var.app}"
          },
          {
            "name": "ENVIRONMENT",
            "value": "${var.environment}"
          },
          {
            "name": "NODE_ENV",
            "value": "${var.environment}"
          }
        ],
        "secrets": [
          {
            "name": "DATABASE_PASSWORD",
            "valueFrom": "${aws_ssm_parameter.db_ssm_secret.arn}"
          },
          {
            "name": "DATABASE_URL",
            "valueFrom": "${aws_ssm_parameter.db_ssm_database.arn}"
          },
          {
            "name": "DATABASE_USERNAME",
            "valueFrom": "${aws_ssm_parameter.db_ssm_username.arn}"
          },
          {
            "name": "DATABASE_NAME",
            "valueFrom": "${aws_ssm_parameter.db_ssm_name.arn}"
          },
          {
            "name": "AWS_ACCESS_KEY",
            "valueFrom": "${aws_ssm_parameter.api_aws_access_key.arn}"
          },
          {
            "name": "AWS_ACCESS_SECRET",
            "valueFrom": "${aws_ssm_parameter.api_aws_access_secret.arn}"
          },
          {
            "name": "BUCKET_NAME",
            "valueFrom": "${aws_ssm_parameter.bucket_name.arn}"
          }
        ],
        "requiresAttributes": [
          {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.logging-driver.awslogs"
          },
          {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "ecs.capability.execution-role-awslogs"
          },
          {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.19"
          },
          {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.task-iam-role"
          },
          {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "com.amazonaws.ecs.capability.docker-remote-api.1.18"
          },
          {
            "targetId": null,
            "targetType": null,
            "value": null,
            "name": "ecs.capability.task-eni"
          }
        ]
      }
    ]
  DEFINITION

  tags = var.tags
}

resource "aws_ecs_service" "app" {
  name             = "${var.app}-${var.environment}"
  cluster          = aws_ecs_cluster.app.id
  launch_type      = "FARGATE"
  task_definition  = "${var.app}-${var.environment}"
  desired_count    = var.replicas
  

  network_configuration {
    assign_public_ip = true
    security_groups = [aws_security_group.nsg_task.id]
    subnets         = split(",", var.private_subnets)
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.id
    container_name   = var.app
    container_port   = var.container_port
  }

  tags                    = var.tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  depends_on = [
    aws_lb_listener.tcp,
    aws_ecs_task_definition.app
  ]
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.app}-${var.environment}"
  retention_in_days = var.logs_retention_in_days
  tags              = var.tags
}

resource "local_file" "write_task_definition" {
  content = templatefile("${path.module}/templates/task-definition.json", {
    requiresCompatibilities = aws_ecs_task_definition.app.requires_compatibilities
    networkMode = aws_ecs_task_definition.app.network_mode
    cpu = aws_ecs_task_definition.app.cpu
    memory = aws_ecs_task_definition.app.memory
    executionRoleArn = aws_ecs_task_definition.app.execution_role_arn
    awslogsGroup = "/fargate/service/${var.app}-${var.environment}"
    region = var.region
    ENVIRONMENT = var.environment
    PORT = var.container_port
    PRODUCT = var.app
    DATABASE_PASSWORD = aws_ssm_parameter.db_ssm_secret.arn
    DATABASE_URL = aws_ssm_parameter.db_ssm_database.arn
    DATABASE_USERNAME = aws_ssm_parameter.db_ssm_username.arn
    DATABASE_NAME = aws_ssm_parameter.db_ssm_name.arn
    AWS_ACCESS_KEY = aws_ssm_parameter.api_aws_access_key.arn
    AWS_ACCESS_SECRET = aws_ssm_parameter.api_aws_access_secret.arn
    BUCKET_NAME = aws_ssm_parameter.bucket_name.arn
    image = var.app
    taskDefinitionArn = aws_ecs_task_definition.app.arn
    family = "${var.app}-${var.environment}"
  })
  filename = "../task_definition.json"
}