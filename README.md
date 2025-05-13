# DevOps Code Challenge - LightFeather

This repository contains a deployment solution for the LightFeather DevOps code challenge. The solution implements a modern cloud infrastructure that deploys a React frontend and Express backend to AWS using a Jenkins CI/CD pipeline and Terraform infrastructure as code.

## Project Overview

The project implements a comprehensive DevOps pipeline that showcases industry best practices for continuous integration and deployment. The system:

1. Deploys a Jenkins server to AWS as the automation hub
2. Establishes a robust CI/CD pipeline for automated testing and deployment
3. Builds and pushes Docker containers to AWS ECR, implementing containerization best practices
4. Deploys frontend and backend applications to AWS ECS using Terraform for infrastructure as code
5. Configures an Application Load Balancer (ALB) with appropriate routing rules and health checks
6. Implements proper security groups and IAM roles following the principle of least privilege
7. Sets up logging and basic monitoring for operational visibility

## Detailed Architecture

The architecture implements a modern microservices approach with containerized applications deployed to a managed container service. Here's a breakdown of each component:

### AWS Infrastructure (Terraform-managed)

#### Compute Layer
- **ECS Cluster**: A logical grouping of tasks running on AWS Fargate, which is a serverless compute engine for containers
- **ECS Services**: Long-running task definitions that maintain a specified number of instances of the frontend and backend containers
- **ECS Task Definitions**: Specifications for how containers should be launched and what resources they require, including CPU, memory, networking, and IAM roles

#### Networking Layer
- **Application Load Balancer**: Routes external HTTP traffic to the appropriate service based on paths or ports
- **Target Groups**: Groups of container instances registered with the load balancer for health monitoring and traffic distribution
- **Security Groups**: Virtual firewalls that control inbound and outbound traffic to resources
  - Load Balancer SG: Allows public HTTP traffic on ports 80 and 8080
  - ECS Services SG: Allows traffic only from the Load Balancer SG

#### Storage Layer
- **ECR Repositories**: Private Docker registries for securely storing and managing container images
- **S3 Bucket**: Object storage for ALB access logs to help with troubleshooting and security analysis

#### Identity & Access Management
- **IAM Roles**: Roles with specific permissions to allow ECS tasks to access AWS services
- **IAM Policies**: Sets of permissions attached to roles that define what actions are allowed

### Jenkins Server Infrastructure (manually created)

- **EC2 Instance**: Hosts the Jenkins server with sufficient CPU and memory for build operations
- **IAM Role**: Provides Jenkins with permissions to interact with AWS services through instance profile
- **Security Group**: Controls access to the Jenkins server
  - Inbound: SSH (22), HTTP (8080) from authorized IPs
  - Outbound: All traffic to support build operations
- **EBS Volume**: Persistent storage for Jenkins configuration and build workspaces

### Communication Flow

1. Users access the frontend through the ALB on port 80
2. The frontend makes API calls to the backend through the ALB on port 8080
3. The backend processes requests and returns responses
4. Jenkins communicates with AWS services using the AWS SDK and CLI
5. Docker images are pulled from ECR when ECS tasks start

## Jenkins Pipeline in Detail

The Jenkins pipeline is defined in the Jenkinsfile using a declarative pipeline syntax. It orchestrates the entire CI/CD process:

### Stage: Checkout
- Uses Git to pull the latest code from the repository
- Ensures a clean workspace for each build

### Stage: Build, Push, & Deploy
1. **Authentication**: Securely authenticates with AWS ECR using AWS credentials
2. **Backend Build**:
   - Builds the backend Docker image with proper tagging based on Git commit hash
   - Implements multi-stage builds to minimize image size
   - Performs dependency installation and validation
   - Tags the image for ECR and pushes it to the repository
3. **Frontend Build**:
   - Builds the frontend using React's production build process
   - Injects the backend API URL as an environment variable during build time
   - Creates a production-optimized Nginx container
   - Tags and pushes the image to ECR
4. **Terraform Apply**:
   - Uses the infrastructure as code approach to update AWS resources
   - Passes the new image tags as variables to Terraform
   - Updates task definitions with the new container images
   - Maintains state in a remote S3 backend with locking via DynamoDB
5. **Force Deployment**:
   - Triggers immediate deployment of the updated ECS services
   - Ensures zero-downtime deployments with proper health checks

### Stage: Smoke Test
- Executes HTTP requests to verify both frontend and backend are accessible
- Tests specific endpoints to confirm basic functionality
- Provides detailed output for debugging if tests fail
- Ensures deployments meet minimum quality standards before being considered successful

## Detailed Deployment Instructions

### Prerequisites

- AWS account with administrative permissions
- Local workstation with:
  - AWS CLI (version 2.x) installed and configured with access keys
  - Terraform (version >= 1.0.0) installed
  - Git client installed
  - Basic understanding of Docker, Terraform, and AWS services

### Step 1: Set up Jenkins Server

1. Launch an EC2 instance with the following specifications:
   - AMI: Amazon Linux 2 or Ubuntu Server 22.04 LTS
   - Instance Type: t3.medium (recommended for build performance)
   - Storage: 30GB gp3 EBS volume (for faster I/O operations)
   - Security Group: Create new with the following rules:
     - Inbound: SSH (port 22) from your IP address
     - Inbound: HTTP (port 8080) from your IP address
     - Outbound: All traffic (0.0.0.0/0)
   - IAM Role: Create new with the following managed policies:
     - AmazonECR-FullAccess
     - AmazonECS-FullAccess
     - AmazonS3FullAccess
     - IAMFullAccess
     - AmazonEC2FullAccess

2. Connect to the instance and install Jenkins with all dependencies:
   ```bash
   # For Ubuntu
   sudo apt update
   sudo apt install -y openjdk-11-jdk
   
   # Add Jenkins repository
   wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
   sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
   sudo apt update
   sudo apt install -y jenkins
   sudo systemctl start jenkins
   sudo systemctl enable jenkins
   
   # Install Docker with proper permissions
   sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
   sudo apt update
   sudo apt install -y docker-ce
   
   # Add jenkins user to docker group
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   
   # Verify Docker installation
   sudo docker run hello-world
   
   # Install AWS CLI version 2
   sudo apt install -y unzip
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Install Terraform
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update
   sudo apt install -y terraform
   
   # Verify all installations
   java -version
   docker --version
   aws --version
   terraform --version
   ```

3. Configure Jenkins with necessary plugins and settings:
   - Retrieve the initial admin password:
     ```bash
     sudo cat /var/lib/jenkins/secrets/initialAdminPassword
     ```
   - Navigate to http://<jenkins-server-ip>:8080 in your browser
   - Enter the initial admin password
   - Select "Install suggested plugins" during setup
   - Install additional plugins:
     - Docker Pipeline
     - AWS Steps
     - Pipeline: AWS Steps
     - Terraform
     - Blue Ocean (for improved pipeline visualization)
   - Create an admin user with secure credentials

4. Configure AWS credentials in Jenkins:
   - Go to Manage Jenkins > Manage Credentials > Jenkins > Global credentials > Add Credentials
   - Select "Username with password" from the dropdown
   - Set the ID to "aws" (this must match the credentialsId in your Jenkinsfile)
   - Enter your AWS Access Key ID as the username
   - Enter your AWS Secret Access Key as the password
   - Set a description like "AWS Access Keys"
   - Click OK to save

5. Create and configure the pipeline job:
   - Click "New Item" on the Jenkins dashboard
   - Enter a name for your pipeline (e.g., "devops-challenge")
   - Select "Pipeline" and click OK
   - In the configuration page:
     - Under "Pipeline", select "Pipeline script from SCM"
     - Select "Git" as the SCM
     - Enter your repository URL
     - Specify the branch (e.g., "*/main")
     - Set the Script Path to "Jenkinsfile"
     - Click "Save"

### Step 2: Prepare AWS Infrastructure

1. Set up Terraform remote state storage:
   ```bash
   # Create S3 bucket for Terraform state
   aws s3 mb s3://lightfeather-terraform-state --region us-east-1
   
   # Enable versioning for the bucket
   aws s3api put-bucket-versioning \
     --bucket lightfeather-terraform-state \
     --versioning-configuration Status=Enabled
   
   # Create DynamoDB table for state locking
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

2. Create ECR repositories for container images:
   ```bash
   # Create frontend repository
   aws ecr create-repository \
     --repository-name lightfeather-frontend \
     --image-scanning-configuration scanOnPush=true \
     --region us-east-1
   
   # Create backend repository
   aws ecr create-repository \
     --repository-name lightfeather-backend \
     --image-scanning-configuration scanOnPush=true \
     --region us-east-1
   ```

3. Ensure your VPC is properly configured:
   - Identify or create a VPC with at least two public subnets in different availability zones
   - Ensure the public subnets have auto-assign public IP enabled
   - Verify that the route tables for these subnets have routes to an Internet Gateway
   - Note the VPC ID and subnet IDs for later configuration

### Step 3: Configure the Project

1. Clone the repository to your local machine:
   ```bash
   git clone <repository-url>
   cd devops-code-challenge
   ```

2. Update environment-specific variables in the Jenkinsfile:
   ```groovy
   environment {
       AWS_REGION   = 'us-east-1'                // Your AWS region
       ECR_ACCOUNT  = '123456789012'             // Your AWS account ID
       CLUSTER      = 'devops-challenge-cluster' // Your ECS cluster name
       BACKEND_TAG  = "build-${GIT_COMMIT[0..6]}"
       FRONTEND_TAG = "build-${GIT_COMMIT[0..6]}"
   }
   ```

3. Create or update the `terraform.tfvars` file with your specific configuration:
   ```hcl
   # AWS region
   aws_region = "us-east-1"
   
   # Terraform state storage
   tf_state_bucket     = "lightfeather-terraform-state"
   tf_state_lock_table = "terraform-state-lock"
   
   # VPC and subnet configuration
   vpc_id = "vpc-0123456789abcdef0"
   public_subnets = [
     "subnet-0123456789abcdef0", # us-east-1a
     "subnet-0123456789abcdef1", # us-east-1b
     "subnet-0123456789abcdef2", # us-east-1c
   ]
   ```

4. Update the configuration files for proper communication between services:
   
   a. In `frontend/src/config.js`, ensure the API_URL is configured properly:
   ```javascript
   export const API_URL = process.env.REACT_APP_API_URL;
   console.log('Frontend API_URL used:', API_URL);
   ```
   
   b. In the Jenkinsfile, update the frontend build command with the correct backend URL:
   ```bash
   docker build --no-cache \
     --build-arg REACT_APP_API_URL=http://your-alb-dns-name:8080 \
     -t frontend:${FRONTEND_TAG} \
     frontend
   ```
   
   c. In the Terraform task definition for the backend, ensure CORS is properly configured:
   ```hcl
   environment = [
     {
       name  = "CORS_ORIGIN"
       value = "http://your-alb-dns-name" # ALB DNS for frontend
     }
   ]
   ```

5. Commit and push your changes:
   ```bash
   git add .
   git commit -m "Update configuration for deployment"
   git push
   ```

### Step 4: Deploy the Application

1. Access your Jenkins server and navigate to your pipeline job.

2. Click "Build Now" to start the pipeline.

3. Monitor the pipeline execution:
   - The "Checkout" stage should complete quickly
   - The "Build, Push, & Deploy" stage will take several minutes as it builds and pushes Docker images and applies Terraform
   - The "Smoke Test" stage will verify that the application is running correctly

4. Pipeline stages explanation:
   - **Checkout**: Clones the Git repository to the Jenkins workspace
   - **Build, Push, & Deploy**:
     - Authenticates with AWS ECR
     - Builds the backend Docker image and pushes it to ECR
     - Builds the frontend Docker image and pushes it to ECR
     - Applies Terraform configuration to update ECS services
     - Forces new deployments on ECS services
   - **Smoke Test**:
     - Tests the frontend by making an HTTP request to the ALB
     - Tests the backend by making an HTTP request to the ALB on port 8080

5. Once the pipeline completes successfully, you can access your application:
   - Frontend: http://<alb-dns-name>
   - Backend API: http://<alb-dns-name>:8080
   - You should see "SUCCESS" followed by a GUID if everything is working correctly

## Terraform Resources Explained

The Terraform configuration provisions the following AWS resources:

### Networking Resources

```hcl
resource "aws_lb" "main" {
  name               = "devops-challenge-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.public_subnets
  
  # Access logs configuration
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "devops-challenge-lb"
    enabled = true
  }
}
```
The Application Load Balancer routes traffic to the frontend and backend services. It's configured with access logging for audit and troubleshooting purposes.

### Container Registry

```hcl
resource "aws_ecr_repository" "frontend" {
  name                 = "lightfeather-frontend"
  image_scanning_configuration {
    scan_on_push = true
  }
}

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
```
The ECR repositories store Docker images for the frontend and backend. Lifecycle policies automatically clean up old images to reduce storage costs.

### Container Orchestration

```hcl
resource "aws_ecs_cluster" "this" {
  name = "devops-challenge-cluster"
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "devops-challenge-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
      essential = true
      portMappings = [
        { containerPort = 80, hostPort = 80, protocol = "tcp" }
      ]
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }
}
```
The ECS cluster runs the containerized applications using AWS Fargate, which is a serverless compute engine for containers. Task definitions specify the container configuration, and services ensure the desired number of containers are running.

### Security

```hcl
resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  description = "Allow inbound traffic to ECS services"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
Security groups control network traffic to and from resources. The ECS services only accept traffic from the ALB for improved security.

## Comprehensive Troubleshooting Guide

### Jenkins Issues

1. **Jenkins Cannot Start**
   - Check the Jenkins service status: `sudo systemctl status jenkins`
   - Review logs: `sudo journalctl -u jenkins`
   - Ensure Java is installed correctly: `java -version`
   - Verify disk space: `df -h`

2. **Cannot Connect to AWS Services**
   - Verify AWS credentials: `aws sts get-caller-identity`
   - Check IAM permissions for the configured user
   - Ensure the credential ID in Jenkins matches the Jenkinsfile
   - Check AWS CLI configuration: `aws configure list`

3. **Docker Build Fails**
   - Ensure Jenkins has Docker permissions: `sudo usermod -aG docker jenkins`
   - Verify Docker service is running: `sudo systemctl status docker`
   - Check disk space for Docker: `docker system df`
   - Test Docker manually: `docker build -t test ./path/to/dockerfile`

### Terraform Issues

1. **Terraform Init Fails**
   - Check S3 bucket permissions
   - Verify AWS credentials have access to S3 and DynamoDB
   - Ensure backend configuration is correct
   - Look for error messages in the output

2. **Terraform Apply Fails**
   - Check IAM permissions for creating resources
   - Verify VPC and subnet IDs are correct
   - Ensure resource names don't conflict with existing resources
   - Look for specific error messages in the output

3. **State Lock Issues**
   - Check if a previous operation left a lock: `terraform force-unlock <LOCK_ID>`
   - Verify DynamoDB table permissions
   - Ensure the DynamoDB table has the correct schema

### ECS Deployment Issues

1. **Tasks Not Starting**
   - Check the ECS console for task failure reasons
   - Verify security group rules allow necessary traffic
   - Check IAM role permissions for task execution
   - Review CloudWatch logs for container errors

2. **Health Checks Failing**
   - Verify health check paths are correct
   - Ensure containers are listening on the expected ports
   - Check ALB security group allows traffic
   - Review the application logs for errors

3. **Services Not Registering with ALB**
   - Verify target group configurations
   - Check that container ports match target group ports
   - Ensure ECS tasks are in the same VPC as the ALB
   - Review network configuration in the ECS task definition

### Application Issues

1. **Frontend Cannot Connect to Backend**
   - Verify CORS configuration in the backend
   - Check the API URL in the frontend build
   - Ensure the ALB listener for the backend is on port 8080
   - Test the backend API directly with curl or Postman

2. **Application Returns Errors**
   - Check application logs in CloudWatch
   - Verify environment variables are set correctly
   - Test the container locally with Docker
   - Review application code for issues

## Enhanced Security Considerations

### Jenkins Security

1. **Access Control**
   - Use HTTPS with a valid certificate
   - Install the Jenkins "Role-based Authorization Strategy" plugin
   - Create separate accounts for different team members with appropriate permissions
   - Implement IP-based restrictions in the security group

2. **Jenkins Configuration**
   - Disable CLI remote access
   - Enable CSRF protection
   - Regularly update Jenkins and plugins
   - Use secrets management solutions like AWS Secrets Manager instead of storing credentials in Jenkins

### AWS Infrastructure Security

1. **Network Security**
   - Use private subnets for ECS tasks where possible
   - Implement network ACLs in addition to security groups
   - Consider adding AWS WAF to the ALB to protect against common web exploits
   - Use VPC Flow Logs to monitor network traffic

2. **IAM Best Practices**
   - Follow the principle of least privilege for all IAM roles
   - Regularly audit and rotate credentials
   - Use IAM roles for EC2 instead of access keys
   - Consider implementing AWS Organizations with SCPs for additional guardrails

3. **Container Security**
   - Enable ECR image scanning
   - Implement a vulnerability management process
   - Use minimal base images (e.g., alpine) to reduce attack surface
   - Never store secrets in container images

4. **Data Protection**
   - Enable encryption for all data storage services
   - Implement S3 bucket policies to prevent public access
   - Consider using AWS KMS for key management
   - Implement proper data classification and handling procedures

## Maintenance and Monitoring

### Routine Maintenance

1. **System Updates**
   - Regularly update the Jenkins server OS
   - Keep Jenkins plugins up to date
   - Update Docker and other tools
   - Rotate credentials periodically

2. **Infrastructure Management**
   - Run Terraform plan regularly to check for drift
   - Review and clean up unused resources
   - Update Terraform modules and providers
   - Keep documentation current

### Monitoring

1. **CloudWatch Monitoring**
   - Set up CloudWatch alarms for ECS service metrics
   - Monitor ALB metrics (e.g., 5xx errors, latency)
   - Create a CloudWatch dashboard for key metrics
   - Set up AWS Health notifications

2. **Logging**
   - Centralize logs in CloudWatch Logs
   - Implement log retention policies
   - Consider log analysis solutions like CloudWatch Logs Insights
   - Set up alerts for critical errors

3. **Performance Monitoring**
   - Monitor container resource utilization
   - Track ALB request counts and latency
   - Set up EC2 monitoring for the Jenkins server
   - Implement tracing with AWS X-Ray for request tracking

## Future Enhancements

1. **Infrastructure Improvements**
   - Implement auto-scaling for ECS services
   - Add CloudFront for content delivery
   - Set up multi-region deployment for high availability
   - Use AWS Secrets Manager for secrets management

2. **CI/CD Enhancements**
   - Implement automated testing in the pipeline
   - Add code quality checks with tools like SonarQube
   - Set up environment promotion (dev, staging, prod)
   - Implement blue/green deployments

3. **Security Enhancements**
   - Add AWS GuardDuty for threat detection
   - Implement AWS Config for compliance monitoring
   - Use AWS Security Hub for comprehensive security posture
   - Set up AWS CloudTrail for API auditing

4. **Monitoring Improvements**
   - Implement distributed tracing
   - Set up synthetic monitoring with CloudWatch Canaries
   - Add real user monitoring (RUM)
   - Create comprehensive dashboards with Grafana or CloudWatch

By following these instructions and best practices, you can successfully deploy, manage, and improve the DevOps infrastructure for the LightFeather code challenge. This README provides a solid foundation for understanding the architecture, deploying the application, and troubleshooting issues that may arise.
