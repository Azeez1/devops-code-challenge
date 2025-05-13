# infra/alb.tf

# Create a new Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "devops-challenge-lb" # Name of the ALB
  internal           = false                 # false for internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id] # Reference to the LB security group
  subnets            = var.public_subnets            # ALB needs to be in public subnets

  # Enable access logs for the ALB (optional but good practice)
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "devops-challenge-lb"
    enabled = true
  }

  tags = {
    Name = "devops-challenge-lb"
  }
}

# Target group for the frontend ECS service
resource "aws_lb_target_group" "frontend" {
  name        = "devops-challenge-frontend-tg"
  port        = 3000 # Port the frontend container listens on
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate

  health_check {
    enabled             = true
    path                = "/" # Health check path for the frontend
    port                = "traffic-port" # Uses the port defined above (3000)
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200" # Expect HTTP 200 for healthy
  }

  tags = {
    Name = "devops-challenge-frontend-tg"
  }
}

# Target group for the backend ECS service
resource "aws_lb_target_group" "backend" {
  name        = "devops-challenge-backend-tg"
  port        = 8080 # Port the backend container listens on
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate

  health_check {
    enabled             = true
    path                = "/health" # Health check path for the backend (assuming /health exists)
    port                = "traffic-port" # Uses the port defined above (8080)
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200" # Expect HTTP 200 for healthy
  }

  tags = {
    Name = "devops-challenge-backend-tg"
  }
}

# Listener for HTTP traffic on port 80 for the frontend
resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn # Forward to frontend target group
  }
}

# Listener for HTTP traffic on port 8080 for the backend
# This makes the backend directly accessible via the ALB on port 8080.
# Often, for security, you might only have the frontend listener and route /api/* paths
# from the frontend listener to the backend target group.
# But for this challenge, a direct listener might be simpler for initial setup.
resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080" # Exposing backend on port 8080 via ALB
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn # Forward to backend target group
  }
}

# S3 bucket for ALB access logs (Optional but included in template)
resource "aws_s3_bucket" "lb_logs" {
  bucket = "devops-challenge-lb-logs-${random_id.bucket_suffix.hex}" # Unique bucket name

  # It's good practice to enable versioning and server-side encryption
  # and set up lifecycle rules for logs, but keeping it simple here.
}

# Random ID to help make S3 bucket name unique (Optional but included in template)
resource "random_id" "bucket_suffix" {
  byte_length = 8
}
