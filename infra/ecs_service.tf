# infra/ecs_service.tf

# Data source for the specified VPC
data "aws_vpc" "selected" { # Renamed from "default" to avoid confusion with AWS default VPC concept if not intended
  id = var.vpc_id
}

# Data source to get all subnets in the specified VPC
data "aws_subnets" "all_in_vpc" { # Renamed from "default" for clarity
  filter {
    name   = "vpc-id"
    values = [var.vpc_id] # Use the explicit VPC ID from your variable
  }
  # If there's a dependency on the VPC data source (though often not strictly necessary for this filter)
  # depends_on = [data.aws_vpc.selected] 
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
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
      essential = true
      portMappings = [
        { containerPort = 80, hostPort = 80, protocol = "tcp" } # Matches ALB TG
      ]
      environment = [
        {
          name  = "REACT_APP_API_URL"
          value = "http://44.192.74.201:8080" # Consider changing this later to use ALB DNS for backend
        }
      ]
    }
  ])
}

# Service for the React frontend
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1 # Start with 1 for easier troubleshooting
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  network_configuration {
    subnets          = data.aws_subnets.all_in_vpc.ids # Use the IDs from the correctly filtered data source
    assign_public_ip = true                            # Ensure these subnets have internet access for image pulling
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }

  depends_on = [aws_lb_listener.frontend_http]
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
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ]
      environment = [
        {
          name  = "CORS_ORIGIN"
          # This should ideally be the ALB's DNS name for the frontend,
          # e.g., "http://${aws_lb.main.dns_name}"
          # For now, using your hardcoded value.
          value = "http://34.205.29.35"
        }
      ]
    }
  ])
}

# Service for the Express backend
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1 # Start with 1 for easier troubleshooting
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080
  }

  network_configuration {
    subnets          = data.aws_subnets.all_in_vpc.ids # Use the IDs from the correctly filtered data source
    assign_public_ip = true                            # Ensure these subnets have internet access
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }

  depends_on = [aws_lb_listener.backend_http]
}
