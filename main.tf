## Author Arun
## Date 07 Nov 2023

provider "aws" {
  region = "us-east-1"  # Change to your desired region
  #version = ">= 2.0"
  version = ">= 1.2.0" # Specify the verssion
}

# Creating a VPC with CIDR of 10.x.x.x
resource "aws_vpc" "quantspark_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "QuantSparkVPC"
  }
}

# Creating two public and two private subnets in different Availability Zones
resource "aws_subnet" "quantspark_public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.quantspark_vpc.id
  cidr_block              = element(["10.0.0.0/24", "10.0.1.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true  # Public subnet

  tags = {
    Name = "QuantSparkPublicSubnet-${count.index}"
  }
}

resource "aws_subnet" "quantspark_private_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.quantspark_vpc.id
  cidr_block              = element(["10.0.2.0/24", "10.0.3.0/24"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = false  # Private subnet

  tags = {
    Name = "QuantSparkPrivateSubnet-${count.index}"
  }
}

# Create an Internet Gateway for the public subnets
resource "aws_internet_gateway" "quantspark_igw" {
  vpc_id = aws_vpc.quantspark_vpc.id

  tags = {
    Name = "QuantSparkIGW"
  }
}

# Attach the Internet Gateway to the public subnets
resource "aws_route" "quantspark_igw_attachment" {
  route_table_id         = aws_vpc.quantspark_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.quantspark_igw.id
  count                  = 2  # Two public subnets
}

# Creating a security group for your ALB and EC2

resource "aws_security_group" "alb_security_group" {
  name        = "ALBSecurityGroup"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.quantspark_vpc.id

  # Define our security group rules here, such as inbound and outbound rules with required IP

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["34.203.39.42/32"] # Arun Public IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating an Application Load Balancer 
resource "aws_lb" "quantspark_lb" {
  name               = "QuantSparkLoadBalancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.quantspark_public_subnet[*].id
  security_groups    = [aws_security_group.alb_security_group.id]

  enable_deletion_protection = false
}

# Creating a target group for the Application Load Balancer
resource "aws_lb_target_group" "quantspark_lb_target_group" {
  name     = "QuantSparkTargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.quantspark_vpc.id
}

# Creating an IAM instance profile for the Auto Scaling Group
resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "ASGInstanceProfile"
  role = aws_iam_role.asg_role.name
}

# Create an Auto Scaling Group
resource "aws_launch_configuration" "quantspark_launch_config" {
  name_prefix = "QuantSparkLaunchConfig"
  image_id    = "ami-06aa3f7caf3a30282"  # Specify your desired AMI based on your region
  instance_type = "t2.micro"  # Adjust the instance type as needed
  iam_instance_profile = aws_iam_instance_profile.asg_instance_profile.name

  security_groups = [aws_security_group.alb_security_group.id]
  # Specify your SSH key pair or pass pub key to incert in ec2
  key_name        = "quantspark"  
  user_data = <<-EOF
    #!/bin/bash

    # Install Python and required packages using below commands
    apt update -y
    apt install -y python3-pip
    pip3 install flask

    # Create a Flask application and adding content to app.py application port 80
    cat <<EOL > /home/ubuntu/app.py
    from flask import Flask
    app = Flask(__name__)

    @app.route('/')
    def hello():
        return "Welcome To QuantSpark Arun Interview Project!"

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=80)
    EOL

    # Start the Flask application using below command
    python3 /home/ubuntu/app.py
    EOF
}

resource "aws_autoscaling_group" "quantspark_asg" {
  name = "QuantSparkASG"
  launch_configuration = aws_launch_configuration.quantspark_launch_config.name
  vpc_zone_identifier = aws_subnet.quantspark_public_subnet[*].id
  target_group_arns  = [aws_lb_target_group.quantspark_lb_target_group.arn]
  min_size           = 2
  max_size           = 4
  desired_capacity   = 2
}

# Creating an IAM role for the Auto Scaling Group
resource "aws_iam_role" "asg_role" {
  name = "ASGRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to the IAM role that grant necessary permissions for your use case 

resource "aws_iam_policy_attachment" "asg_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"  
  name       = "EC2FullAccess"
  roles      = [aws_iam_role.asg_role.name]
}

# Output the DNS name of the Load Balancer to access the application 
output "load_balancer_dns" {
  value = aws_lb.quantspark_lb.dns_name
}

# Creating an ALB listener rule with port 80

resource "aws_lb_listener" "quantspark_lb_listener" {
  load_balancer_arn = aws_lb.quantspark_lb.arn
  port             = 80
  protocol         = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quantspark_lb_target_group.arn
  }
}
