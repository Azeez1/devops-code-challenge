# infra/alb.tf

# Create a new Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "devops-challenge-lb" # Name of the ALB
  internal           = false                 # false for internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id] # Reference to the LB security group defined in security_group.tf
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
    path                = "/health" # Health check path for the backend
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
resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080" # Exposing backend on port 8080 via ALB
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn # Forward to backend target group
  }
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "lb_logs" {
  bucket = "devops-challenge-lb-logs-${random_id.bucket_suffix.hex}" 
}

# Random ID to help make S3 bucket name unique
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Add this new resource for the S3 bucket policy
resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = aws_s3_bucket.lb_logs.id # Reference the bucket created by Terraform

  # Policy document from AWS documentation for enabling ALB access logs
  # See: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::127311923021:root" # ELB Account ID for us-east-1
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.lb_logs.arn}/devops-challenge-lb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        # The prefix "devops-challenge-lb" must match the prefix in your aws_lb access_logs block.
        # data.aws_caller_identity.current.account_id gets your current AWS account ID.
      },
      {
        Effect    = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.lb_logs.arn}/devops-challenge-lb/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect    = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.lb_logs.arn
      }
    ]
  })
}

# Add this data source to get your current AWS Account ID
data "aws_caller_identity" "current" {}
