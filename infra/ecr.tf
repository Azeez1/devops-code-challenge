# ECR repo for the React frontend
resource "aws_ecr_repository" "frontend" {
  name                 = "devops-challenge-frontend"
  image_scanning_configuration {
    scan_on_push = true
  }
  lifecycle_policy {
    lifecycle_policy_body = <<POLICY
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
}

# ECR repo for the Express backend
resource "aws_ecr_repository" "backend" {
  name                 = "devops-challenge-backend"
  image_scanning_configuration {
    scan_on_push = true
  }
  lifecycle_policy {
    lifecycle_policy_body = <<POLICY
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
}
