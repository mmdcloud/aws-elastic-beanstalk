# resource "aws_s3_bucket" "theplayer007_nodeapp" {
#   bucket = "theplayer007-nodeapp"
# }

# resource "aws_s3_object" "nodeapp-object" {
#   bucket = aws_s3_bucket.theplayer007_nodeapp.id
#   key    = "nodeapp.zip"
#   source = "./files/nodeapp.zip"
# }

# # VPC Creation
# resource "aws_vpc" "vpc" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "vpc"
#   }
# }

# resource "aws_subnet" "public_subnets" {
#   count             = length(var.public_subnet_cidrs)
#   vpc_id            = aws_vpc.vpc.id
#   cidr_block        = element(var.public_subnet_cidrs, count.index)
#   availability_zone = element(var.azs, count.index)
#   tags = {
#     Name = "public subnet ${count.index + 1}"
#   }
# }

# resource "aws_subnet" "private_subnets" {
#   count             = length(var.private_subnet_cidrs)
#   vpc_id            = aws_vpc.vpc.id
#   cidr_block        = element(var.private_subnet_cidrs, count.index)
#   availability_zone = element(var.azs, count.index)
#   tags = {
#     Name = "private subnet ${count.index + 1}"
#   }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.vpc.id
#   tags = {
#     Name = "igw"
#   }
# }

# resource "aws_route_table" "route_table" {
#   vpc_id = aws_vpc.vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
#   tags = {
#     Name = "route table"
#   }
# }

# resource "aws_route_table_association" "route_table_association" {
#   count          = length(var.public_subnet_cidrs)
#   subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
#   route_table_id = aws_route_table.route_table.id
# }

# # Elastic Beanstalk Role
# resource "aws_iam_role" "elasticbeanstalk-role" {
#   name               = "elasticbeanstalk-role"
#   assume_role_policy = <<EOF
#     {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#         "Effect": "Allow",
#         "Principal": {
#             "Service": "elasticbeanstalk.amazonaws.com"
#         },
#         "Action": "sts:AssumeRole"
#         }
#     ]
#     }
#     EOF
# }

# # # AppRunnerECRAccess policy attachment 
# # resource "aws_iam_role_policy_attachment" "elasticbeanstalk-managed-updates-role-policy-attachment" {
# #   role       = aws_iam_role.elasticbeanstalk-role.name
# #   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
# # }

# # # AppRunnerECRAccess policy attachment 
# # resource "aws_iam_role_policy_attachment" "elasticbeanstalk-enhanced-health-role-policy-attachment" {
# #   role       = aws_iam_role.elasticbeanstalk-role.name
# #   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
# # }

# # Create elastic beanstalk application
# resource "aws_elastic_beanstalk_application" "nodeapp" {
#   name        = "nodeapp"
#   description = "nodeapp"
#   appversion_lifecycle {
#     delete_source_from_s3 = true
#     service_role          = aws_iam_role.elasticbeanstalk-role.arn
#   }
# }

# # Create elastic beanstalk Environment
# resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
#   name                = "nodeapp-env"
#   application         = aws_elastic_beanstalk_application.nodeapp.name
#   solution_stack_name = "64bit Amazon Linux 2023 v6.2.1 running Node.js 20"
#   tier                = "WebServer"
  
#   setting {
#     namespace = "aws:elasticbeanstalk:application"
#     name      = "Application Healthcheck URL"
#     value     = "/"
#   }

#   setting {
#     namespace = "aws:ec2:vpc"
#     name      = "VPCId"
#     value     = aws_vpc.vpc.id
#   }

#   setting {
#     namespace = "aws:autoscaling:launchconfiguration"
#     name      = "IamInstanceProfile"
#     value     = aws_iam_role.elasticbeanstalk-role.arn
#   }

#   setting {
#     namespace = "aws:ec2:vpc"
#     name      = "AssociatePublicIpAddress"
#     value     = true
#   }

#   setting {
#     namespace = "aws:ec2:vpc"
#     name      = "Subnets"
#     value     = aws_subnet.public_subnets[0].id
#   }

#   setting {
#     namespace = "aws:ec2:vpc"
#     name      = "ELBScheme"
#     value     = "public"
#   }

#   setting {
#     namespace = "aws:elasticbeanstalk:environment"
#     name      = "LoadBalancerType"
#     value     = "application"
#   }

#   setting {
#     namespace = "aws:ec2:instances"
#     name      = "InstanceTypes"
#     value     = jsonencode(["t2.micro","t3.micro"])
#   }

#   setting {
#     namespace = "aws:ec2:instances"
#     name      = "EnableSpot"
#     value     = false
#   }
  
#   setting {
#     namespace = "aws:autoscaling:asg"
#     name      = "MinSize"
#     value     = 1
#   }
  
#   setting {
#     namespace = "aws:autoscaling:asg"
#     name      = "MaxSize"
#     value     = 2
#   }
# }

# resource "aws_elastic_beanstalk_application_version" "nodeapp_version" {
#   name        = "nodeapp_version"
#   application = aws_elastic_beanstalk_application.nodeapp.name
#   description = "Node.js based application deployed on Elastic Beanstalk"
#   bucket      = aws_s3_bucket.theplayer007_nodeapp.id
#   key         = aws_s3_object.nodeapp-object.id
#   depends_on = [ aws_s3_bucket.theplayer007_nodeapp ]
# }

# VPC Configuration
resource "aws_vpc" "prod_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "prod-vpc"
  }
}

# Subnets
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.prod_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod_vpc.id
  tags = {
    Name = "prod-igw"
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for Elastic Beanstalk
resource "aws_security_group" "eb_sg" {
  name        = "eb-production-sg"
  description = "Security group for Elastic Beanstalk environment"
  vpc_id      = aws_vpc.prod_vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eb-production-sg"
  }
}

# RDS Database (PostgreSQL example)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-production-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eb_sg.id]
  }

  tags = {
    Name = "rds-production-sg"
  }
}

resource "aws_db_instance" "production_db" {
  identifier             = "prod-db"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres${replace(var.db_engine_version, "/\\.\\d+$/", "")}"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = false
  final_snapshot_identifier = "prod-db-final-snapshot"
  backup_retention_period = 7
  backup_window           = "03:00-06:00"
  maintenance_window      = "sun:06:00-sun:08:00"
  multi_az                = true
  deletion_protection     = true

  tags = {
    Name = "production-db"
  }
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "prod_app" {
  name        = var.app_name
  description = "Production application"
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "prod_env" {
  name                = "${var.app_name}-prod"
  application         = aws_elastic_beanstalk_application.prod_app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.5 running Docker" # Update to your desired platform

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.prod_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", aws_subnet.public_subnets[*].id)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", aws_subnet.public_subnets[*].id)
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.min_instances
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.max_instances
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "50"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "IgnoreHealthCheck"
    value     = "false"
  }

  # Environment variables (including DB connection)
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.production_db.endpoint}/${var.db_name}"
  }

  # Add other environment variables as needed
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "production"
  }

  tags = {
    Environment = "production"
  }
}