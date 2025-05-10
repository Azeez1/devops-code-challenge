# ECR repo for the React frontend
resource "aws_ecr_repository" "frontend" {
  # Repository for Docker images of the React app
  name = "lightfeather-frontend"

  # Scan images on push for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy for frontend images
resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy     = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only the last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }
  ]
}
POLICY
}

# ECR repo for the Express backend
resource "aws_ecr_repository" "backend" {
  # Repository for Docker images of the Express API
  name = "lightfeather-backend"

  # Scan images on push for vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy for backend images
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy     = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only the last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }
  ]
}
POLICY
}
