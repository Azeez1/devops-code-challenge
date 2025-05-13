# infra/ecs_service.tf

# ... (other parts of the file remain the same) ...

# Task Definition for the React frontend
resource "aws_ecs_task_definition" "frontend" {
  family                   = "devops-challenge-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn # Make sure aws_iam_role.ecs_task_execution is defined (it is in your ecs.tf)

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
      essential = true
      portMappings = [
        # --- CHANGE THIS LINE ---
        { containerPort = 3000, hostPort = 3000, protocol = "tcp" } # Port for ALB to target
        # --- END CHANGE ---
      ]
      environment = [
        {
          name  = "REACT_APP_API_URL"
          # This still points to the direct IP. Consider if you want the frontend 
          # to call the backend via the ALB's port 8080 listener eventually.
          # If so, this URL would change to something like "http://<ALB_DNS_NAME>:8080"
          # For now, leaving it as is, as the backend listener on ALB also uses port 8080.
          value = "http://44.192.74.201:8080" 
        }
      ]
    }
  ])
}

# Service for the React frontend
resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id # Make sure aws_ecs_cluster.this is defined (it is in your ecs.tf)
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2 # Consider starting with 1 for testing, then scale up.
  launch_type     = "FARGATE"

  # Ensure the ECS service is associated with the ALB
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000 # This MUST match the containerPort in portMappings AND the target group port
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids # Using default subnets from your VPC
    assign_public_ip = true # Fargate tasks in public subnets need this if not using NAT Gateway for outbound
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }

  # Add depends_on if there are explicit dependencies, e.g., on the ALB listener
  depends_on = [aws_lb_listener.frontend_http]
}

# Task Definition for the Express backend
resource "aws_ecs_task_definition" "backend" {
  family                   = "devops-challenge-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn # From ecs.tf

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
          # This should ideally be the ALB's DNS name, not a hardcoded IP if the frontend is served via ALB
          # For now, keeping your value. If frontend is at http://<ALB_DNS_NAME>, this should be http://<ALB_DNS_NAME>
          value = "http://34.205.29.35" 
        }
      ]
    }
  ])
}

# Service for the Express backend
resource "aws_ecs_service" "backend" {
  name            = "backend-service"
  cluster         = aws_ecs_cluster.this.id # From ecs.tf
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2 # Consider starting with 1
  launch_type     = "FARGATE"

  # Ensure the ECS service is associated with the ALB
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080 # This MUST match the containerPort in portMappings AND the target group port
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }

  # Add depends_on if there are explicit dependencies
  depends_on = [aws_lb_listener.backend_http]
}

# Data sources for default VPC (moved from the top for clarity, already present)
data "aws_vpc" "default" {
  default = true
}
 data "aws_subnets" "default" {
   filter {
     name   = "vpc-id"
     values = [var.vpc_id] # Changed to use var.vpc_id
   }
 }
