# QuantSpark
QuantSpark

# Terraform Infrastructure for a Simple Web Application with HA

This Terraform code `main.tf` file creates a basic AWS infrastructure setup for a web application. It includes the following components:

- **VPC**: A Virtual Private Cloud (VPC) with 2 public and 2 private subnets distributed across different Availability Zones.

- **EC2 Instances**: An Elastic Compute Cloud (EC2) instance launched as part of an Auto Scaling Group (ASG) and Launch Configuration (LC) with different AZ.

- **IAM Role**: An IAM role associated with the EC2 instances.

- **ALB (Application Load Balancer)**: An Application Load Balancer configured with a Target Group.

- **Flask Python Application**: A simple Flask Python application that serves a "Welcome To QuantSpark Arun Interview Project!" message. The application is launched on the EC2 instances using user data.

## Prerequisites

Before running this code, ensure the following prerequisites are met:

- **AWS Key Pair**: Create an AWS key pair in your AWS account or use existing one for the chosen region. The code assumes the use of the key pair in the specified region (e.g., us-east-1 - North Virginia). Modify the region and key pair name in the code if needed.

## Usage

This Terraform code is contained in a single file and includes all the necessary resources and the Terraform provider configuration. To deploy the infrastructure:

1. Clone this repository to your local environment.

2. Make sure you have Terraform installed and configured with your AWS credentials.

3. Modify the code if necessary, such as changing the region, Tag, AMI ID or key pair.

4. Run the following Terraform commands:

`terraform init`
`terraform plan`
`terraform apply`


5. Review the output, which will include the DNS name of the Application Load Balancer (ALB). You can use this DNS name to access the web application after the deployment.
Note: may be need to wait for 60 - 120 seconds for instance become healthy

## Updating the Application

To update the web application, you can modify the user data section in the Terraform code. This allows you to change the application logic or deploy a different application using Terraform apply.

Feel free to customize this Terraform code according to your specific requirements.

---

**Note**: This is a simple example intended for learning and testing. For a production-ready setup, consider implementing best practices for security, scalability, and reliability. also for production heighly recommanded AWS EKS so we can explore more features like cluster autoscalling, HA in application, GitOps in place etc. 

EKS not used in this because of cost optimization 
The current terraform EC2 also deployed in public because of reduce NAT gateway cost
Cloud watch not enable to reduce Cost
