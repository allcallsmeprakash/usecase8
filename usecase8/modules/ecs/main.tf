# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-ecs-task-execution-role"
  }
}

# ECS Task Execution Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for ECR access
resource "aws_iam_role_policy" "ecs_task_execution_role_policy" {
  name = "${var.environment}-ecs-task-execution-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-ecs-task-role"
  }
}

# ECS Task Role Policy for application-specific permissions
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name = "${var.environment}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.environment}-ecs-tasks-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ecs-tasks-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.environment}-cluster"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Patient Service
resource "aws_cloudwatch_log_group" "patient_service" {
  name              = "/ecs/${var.environment}/patient-service"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-patient-service-logs"
    Service     = "patient-service"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Appointment Service
resource "aws_cloudwatch_log_group" "appointment_service" {
  name              = "/ecs/${var.environment}/appointment-service"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-appointment-service-logs"
    Service     = "appointment-service"
    Environment = var.environment
  }
}

# ECS Task Definition for Patient Service
resource "aws_ecs_task_definition" "patient_service" {
  family                   = "${var.environment}-patient-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "patient-service"
      image = "${var.patient_repo_uri}:latest"
      
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
  

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.patient_service.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring("3000")
        }
      ]

      essential = true
    }
  ])

  tags = {
    Name        = "${var.environment}-patient-service-task"
    Service     = "patient-service"
    Environment = var.environment
  }
}


# Data source for current AWS region
data "aws_region" "current" {
}

# ECS Task Definition for Appointment Service
resource "aws_ecs_task_definition" "appointment_service" {
  family                   = "${var.environment}-appointment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "appointment-service"
      image = "${var.appointment_repo_uri}:latest"
      
      portMappings = [
        {
          containerPort = 3001
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.appointment_service.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring("3001")
        }
      ]

      essential = true
    }
  ])

  tags = {
    Name        = "${var.environment}-appointment-service-task"
    Environment = var.environment
  }
}

# ECS Service for Patient Service
resource "aws_ecs_service" "patient_service" {
  name            = "${var.environment}-patient-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.patient_service.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.patient_target_group_arn
    container_name   = "patient-service"
    container_port   = "3000"
  }

  depends_on = [var.patient_target_group_arn]

  tags = {
    Name        = "${var.environment}-patient-service"
    Service     = "patient-service"
    Environment = var.environment
  }
}

# ECS Service for Appointment Service
resource "aws_ecs_service" "appointment_service" {
  name            = "${var.environment}-appointment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.appointment_service.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.appointment_target_group_arn
    container_name   = "appointment-service"
    container_port   = "3001"
  }

  depends_on = [var.appointment_target_group_arn]

  tags = {
    Name        = "${var.environment}-appointment-service"
    Service     = "appointment-service"
    Environment = var.environment
  }
}
