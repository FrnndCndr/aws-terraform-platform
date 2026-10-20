data "aws_region" "current" {}

data "aws_partition" "current" {}

locals {
  cluster_name        = "ecs-${var.product}-${var.environment}"
  service_full_name   = "ecs-${var.product}-${var.service_name}-${var.environment}"
  task_family         = "task-${var.product}-${var.service_name}-${var.environment}"
  execution_role_name = "iam-${var.product}-${var.service_name}-execution-${var.environment}"
  task_role_name      = "iam-${var.product}-${var.service_name}-task-${var.environment}"
  security_group_name = "secgroup-${var.product}-${var.service_name}-${var.environment}"
  log_group_name      = "/ecs/${var.product}-${var.service_name}-${var.environment}"
  namespace_name      = "${var.product}-${var.environment}.internal"
  secret_arns         = distinct([for secret in values(var.secrets) : secret.secret_arn])

  container_definition = {
    name      = var.service_name
    image     = var.image
    essential = true

    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }
    ]

    environment = [
      for name, value in var.container_environment : {
        name  = name
        value = value
      }
    ]

    secrets = [
      for name, secret in var.secrets : {
        name      = name
        valueFrom = secret.json_key == null ? secret.secret_arn : "${secret.secret_arn}:${secret.json_key}::"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service.name
        "awslogs-region"        = data.aws_region.current.region
        "awslogs-stream-prefix" = var.service_name
      }
    }

    healthCheck = var.health_check == null ? null : {
      command     = var.health_check.command
      interval    = var.health_check.interval_seconds
      timeout     = var.health_check.timeout_seconds
      retries     = var.health_check.retries
      startPeriod = var.health_check.start_period_seconds
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_cloudwatch_log_group" "service" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = local.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "read_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = local.secret_arns
  }
}

resource "aws_iam_role_policy" "read_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name   = "read-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_secrets[0].json
}

resource "aws_iam_role" "task" {
  name               = local.task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy" "task" {
  for_each = var.task_role_policies

  name   = each.key
  role   = aws_iam_role.task.id
  policy = each.value
}

data "aws_iam_policy_document" "execute_command" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execute_command" {
  count = var.enable_execute_command ? 1 : 0

  name   = "execute-command"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.execute_command.json
}

resource "aws_security_group" "service" {
  name        = local.security_group_name
  description = "Tasks of the ${var.service_name} service"
  vpc_id      = var.vpc_id

  tags = {
    Name = local.security_group_name
  }
}

resource "aws_vpc_security_group_egress_rule" "service" {
  security_group_id = aws_security_group.service.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "service" {
  for_each = var.ingress_security_group_ids

  security_group_id            = aws_security_group.service.id
  description                  = "Container port from ${each.key}"
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = each.value
}

resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = local.namespace_name
  description = "Service discovery of ${var.product}-${var.environment}"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "this" {
  name          = var.service_name
  force_destroy = true

  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.this.id
    routing_policy = "MULTIVALUE"

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = jsonencode([local.container_definition])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }
}

resource "aws_ecs_service" "this" {
  name                   = local.service_full_name
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = var.assign_public_ip
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = var.service_name
    container_port = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [
    aws_iam_role_policy_attachment.execution,
    aws_iam_role_policy.read_secrets,
  ]
}
