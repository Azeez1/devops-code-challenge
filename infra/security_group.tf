# infra/security_group.tf

# Security Group for ECS Services
resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Allow inbound traffic to ECS services"
  vpc_id      = var.vpc_id # Changed from data.aws_vpc.default.id to use your declared vpc_id variable

  # Ingress for Frontend (port 3000) from ALB
  ingress {
    description     = "Allow Frontend port (3000) from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id] # Allow traffic only from the ALB SG
  }

  # Ingress for Backend (port 8080) from ALB
  ingress {
    description     = "Allow Backend port (8080) from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id] # Allow traffic only from the ALB SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-challenge-ecs-service-sg"
  }
}

# Security Group for the Application Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "devops-challenge-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere for Frontend Listener"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP on 8080 from anywhere for Backend Listener"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # If you plan to use HTTPS later for the ALB (port 443), add this:
  # ingress {
  #   description = "Allow HTTPS from anywhere"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-challenge-alb-sg"
  }
}
