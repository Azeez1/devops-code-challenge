# ECR repo for the React frontend
resource "aws_ecr_repository" "frontend" {
  # The actual repository name you choose must be unique in your AWS account.
  # e.g., to match your S3 bucket prefix, use "lightfeather-frontend"
  name                 = "lightfeather-frontend"

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle_policy {
    # Lifecycle rule: keep only the last 10 images to save space
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
  # Use a matching naming scheme, e.g., "lightfeather-backend"
  name                 = "lightfeather-backend"

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle_policy {
    # Lifecycle rule: keep only the last 10 images to save space
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
