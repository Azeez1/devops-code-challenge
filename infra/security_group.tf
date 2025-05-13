resource "aws_security_group" "lb_sg" { // This local name now matches what alb.tf expects
  name        = "devops-challenge-alb-sg"      // Name of the SG in AWS
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id                   // Use the VPC ID variable

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
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

  # If your backend listener on the ALB is on port 8080 as per your alb.tf
  ingress {
    description = "Allow HTTP on 8080 from anywhere (for backend via ALB)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
