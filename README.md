Here's a comprehensive README.md file for your DevOps code challenge project, based on the requirements and your implementation:

```markdown
# DevOps Code Challenge - LightFeather

This repository contains a deployment solution for the LightFeather DevOps code challenge. The solution deploys a React frontend and Express backend to AWS using a Jenkins CI/CD pipeline and Terraform infrastructure as code.

## Project Overview

The project implements a full DevOps pipeline that:

1. Deploys a Jenkins server to AWS
2. Uses Jenkins to automate the CI/CD pipeline
3. Builds and pushes Docker containers to AWS ECR
4. Deploys the frontend and backend applications to AWS ECS using Terraform
5. Configures an Application Load Balancer (ALB) to route traffic to the applications

## Architecture

The architecture consists of the following components:

### AWS Infrastructure (Terraform-managed)
- **ECS Cluster**: Hosts the containerized applications
- **ECS Services**: Manages the frontend and backend task definitions
- **Application Load Balancer**: Routes traffic to the frontend and backend
- **ECR Repositories**: Stores Docker images for the frontend and backend
- **Security Groups**: Controls inbound/outbound traffic
- **S3 Bucket**: Stores ALB access logs
- **IAM Roles**: Provides necessary permissions for ECS tasks

### Jenkins Server (manually created)
- **EC2 Instance**: Hosts the Jenkins server
- **IAM Role**: Provides Jenkins with permissions to interact with AWS services
- **Security Group**: Controls inbound/outbound traffic

## Jenkins Pipeline

The pipeline automates the following steps:
1. Checkout code from GitHub
2. Build Docker images for frontend and backend
3. Push Docker images to ECR repositories
4. Apply Terraform configuration to update ECS services
5. Force new deployments on ECS
6. Run smoke tests to verify the deployment

## Deployment Instructions

### Prerequisites

- AWS account with administrative permissions
- AWS CLI installed and configured
- Terraform (>= 1.0.0)
- Git

### Step 1: Set up Jenkins Server

1. Launch an EC2 instance with the following specifications:
   - AMI: Amazon Linux 2 or Ubuntu Server LTS
   - Instance Type: t3.medium (recommended)
   - Storage: At least 30GB

2. Install Jenkins:
   ```bash
   # For Ubuntu
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
   sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
   sudo apt update
   sudo apt install -y jenkins
   sudo systemctl start jenkins
   sudo systemctl enable jenkins
   
   # Install Docker
   sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
   sudo apt update
   sudo apt install -y docker-ce
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   
   # Install AWS CLI
   sudo apt install -y unzip
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Install Terraform
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update
   sudo apt install -y terraform
   ```

3. Configure Jenkins:
   - Navigate to http://<jenkins-server-ip>:8080
   - Follow the setup wizard to install recommended plugins
   - Create an admin user

4. Add AWS credentials to Jenkins:
   - Go to Manage Jenkins > Manage Credentials
   - Add credentials of type "Username with password"
   - Set the ID to "aws"
   - Set the username to your AWS Access Key ID
   - Set the password to your AWS Secret Access Key

5. Create the pipeline job:
   - Create a new Pipeline job
   - Configure SCM to use Git and provide your repository URL
   - Set the Script Path to "Jenkinsfile"

### Step 2: Prepare AWS Infrastructure

1. Create ECR repositories:
   ```bash
   aws ecr create-repository --repository-name lightfeather-frontend
   aws ecr create-repository --repository-name lightfeather-backend
   ```

2. Create an IAM role for Jenkins with the following permissions:
   - AmazonECR-FullAccess
   - AmazonECS-FullAccess
   - AmazonS3FullAccess
   - IAMFullAccess
   - AmazonEC2FullAccess

### Step 3: Configure the Project

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd devops-code-challenge
   ```

2. Update the environment variables in the Jenkinsfile:
   - `AWS_REGION`: Your AWS region (e.g., us-east-1)
   - `ECR_ACCOUNT`: Your AWS account ID
   - `CLUSTER`: Name of your ECS cluster (e.g., devops-challenge-cluster)

3. Update the `terraform.tfvars` file with your specific configuration:
   ```hcl
   aws_region          = "us-east-1"
   tf_state_bucket     = "your-terraform-state-bucket"
   tf_state_lock_table = "your-terraform-state-lock-table"
   vpc_id              = "your-vpc-id"
   public_subnets      = ["subnet-1", "subnet-2", "subnet-3", ...]
   ```

4. Update the frontend and backend configurations:
   - In `frontend/src/config.js`: Update `API_URL` with your backend API URL
   - In the Jenkinsfile, update the `REACT_APP_API_URL` value in the frontend build step

### Step 4: Deploy the Application

1. Push your code to the repository connected to Jenkins.

2. Run the Jenkins pipeline:
   - Go to your Jenkins job
   - Click "Build Now"
   - The pipeline will execute all steps automatically

3. Monitor the deployment:
   - Check the Jenkins console output for any errors
   - Verify the ECS services are running in the AWS console
   - Access the frontend application at http://<alb-dns-name>
   - Test the backend API at http://<alb-dns-name>:8080/health

## Infrastructure Components

### Terraform Resources

- **ECS Cluster**: `aws_ecs_cluster.this`
- **Task Definitions**: `aws_ecs_task_definition.frontend` and `aws_ecs_task_definition.backend`
- **ECS Services**: `aws_ecs_service.frontend` and `aws_ecs_service.backend`
- **Application Load Balancer**: `aws_lb.main`
- **Target Groups**: `aws_lb_target_group.frontend` and `aws_lb_target_group.backend`
- **Security Groups**: `aws_security_group.lb_sg` and `aws_security_group.ecs_service_sg`
- **IAM Role for ECS Tasks**: `aws_iam_role.ecs_task_execution`
- **ECR Repositories**: `aws_ecr_repository.frontend` and `aws_ecr_repository.backend`
- **S3 Bucket for ALB Logs**: `aws_s3_bucket.lb_logs`

### Jenkins Server Infrastructure (Manually Created)

- **EC2 Instance**: Hosts the Jenkins server
- **IAM Role**: Provides Jenkins with permissions to interact with AWS services
- **Security Group**: Controls inbound/outbound traffic
  - Port 22 (SSH) from your IP
  - Port 8080 (HTTP) for Jenkins web UI
  - Outbound access to all destinations

## Troubleshooting

- **Jenkins cannot connect to AWS**: Verify the AWS credentials are correctly configured in Jenkins
- **Docker build fails**: Ensure that Jenkins has permission to run Docker commands
- **Terraform apply fails**: Check that the IAM role has the necessary permissions
- **ECS services not starting**: Check the ECS console for task failure reasons
- **Frontend cannot connect to backend**: Verify the CORS configuration in the backend and the API URL in the frontend

## Security Considerations

- The Jenkins server is publicly accessible. Consider implementing additional security measures:
  - Use HTTPS with a valid certificate
  - Implement IP-based restrictions on the security group
  - Set up a reverse proxy with authentication
- AWS credentials are stored in Jenkins. Consider using IAM roles for EC2 instead of access keys
- The ALB is publicly accessible. Consider implementing WAF rules to protect against common attacks

