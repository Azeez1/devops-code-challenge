# Create an ECS cluster where your containers will run
resource "aws_ecs_cluster" "this" {
  name = "devops-challenge-cluster"
}

# Define the IAM assume-role policy for ECS tasks
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create an IAM role that ECS tasks will assume to pull images and write logs
resource "aws_iam_role" "ecs_task_execution" {
  name               = "devops-challenge-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# Attach the AWS-managed policy for ECS task execution permissions
resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
