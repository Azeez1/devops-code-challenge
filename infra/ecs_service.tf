# ecs_service.tf

# Data sources for default VPC and its subnets
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}



# Task Definition for the React frontend
resource "aws_ecs_task_definition" "frontend" {
  family                   = "devops-challenge-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

container_definitions = jsonencode([
  {
    name      = "backend"
    image     = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
    essential = true
    portMappings = [{ containerPort = 8080, hostPort = 8080 }]
    environment = [
      # Allow CORS from your frontend’s public IP
      { name  = "CORS_ORIGIN",      value = "http://34.205.29.35" }
    ]
  },
  {
    name      = "frontend"
    image     = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
    essential = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
    environment = [
      # Tell React where to call the backend in production
      { name  = "REACT_APP_API_URL", value = "http://44.192.74.201:8080" }
    ]
  }
])

}

# Service for the React frontend (public)
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }
}

# Task Definition for the Express backend
resource "aws_ecs_task_definition" "backend" {
  family                   = "devops-challenge-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name         = "backend"
      image        = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
      essential    = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Service for the Express backend (internal/public as needed)
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true  # set true to allow direct testing; adjust as needed
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }
}
