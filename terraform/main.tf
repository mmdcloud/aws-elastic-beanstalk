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
module "vpc" {
  source                = "./modules/vpc/vpc"
  vpc_name              = "vpc"
  vpc_cidr_block        = "10.0.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  internet_gateway_name = "vpc_igw"
}

# Public Subnets
module "public_subnets" {
  source = "./modules/vpc/subnets"
  name   = "public subnet"
  subnets = [
    {
      subnet = "10.0.1.0/24"
      az     = "${var.aws_region}a"
    },
    {
      subnet = "10.0.2.0/24"
      az     = "${var.aws_region}b"
    },
    {
      subnet = "10.0.3.0/24"
      az     = "${var.aws_region}c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = true
}

# Private Subnets
module "private_subnets" {
  source = "./modules/vpc/subnets"
  name   = "private subnet"
  subnets = [
    {
      subnet = "10.0.6.0/24"
      az     = "${var.aws_region}a"
    },
    {
      subnet = "10.0.5.0/24"
      az     = "${var.aws_region}b"
    },
    {
      subnet = "10.0.4.0/24"
      az     = "${var.aws_region}c"
    }
  ]
  vpc_id                  = module.vpc.vpc_id
  map_public_ip_on_launch = false
}

# Public Route Table
module "public_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "public route table"
  subnets = module.public_subnets.subnets[*]
  routes = [
    {
      cidr_block     = "0.0.0.0/0"
      gateway_id     = module.vpc.igw_id
      nat_gateway_id = ""
    }
  ]
  vpc_id = module.vpc.vpc_id
}

# Public Route Table
module "private_rt" {
  source  = "./modules/vpc/route_tables"
  name    = "private route table"
  subnets = module.private_subnets.subnets[*]
  routes  = []
  vpc_id  = module.vpc.vpc_id
}

# RDS Security Group
module "rds_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc.vpc_id
  name   = "rds_sg"
  ingress = [
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = []
      security_groups = [module.eb_sg.id]
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# Elastic beanstalk Security Group
module "eb_sg" {
  source = "./modules/vpc/security_groups"
  vpc_id = module.vpc.vpc_id
  name   = "eb_sg"
  ingress = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = []
      security_groups = ["0.0.0.0/0"]
      description     = "any"
    },
    {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = []
      security_groups = ["0.0.0.0/0"]
      description     = "any"
    },
    {
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      self            = "false"
      cidr_blocks     = []
      security_groups = ["0.0.0.0/0"]
      description     = "any"
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

## IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

module "db" {
  source                          = "./modules/rds"
  db_name                         = "db"
  allocated_storage               = 100
  storage_type                    = "gp3"
  engine                          = "postgres"
  engine_version                  = "13.4"
  instance_class                  = "db.r6g.large"
  multi_az                        = true
  username                        = tostring(data.vault_generic_secret.rds.data["username"])
  password                        = tostring(data.vault_generic_secret.rds.data["password"])
  subnet_group_name               = "rds_subnet_group"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  backup_retention_period         = 35
  backup_window                   = "03:00-06:00"
  subnet_group_ids = [
    module.private_subnets.subnets[0].id,
    module.private_subnets.subnets[1].id,
    module.private_subnets.subnets[2].id
  ]
  vpc_security_group_ids                = [module.rds_sg.id]
  publicly_accessible                   = false
  deletion_protection                   = true
  skip_final_snapshot                   = false
  max_allocated_storage                 = 500
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring_role.arn
  parameter_group_name                  = "db-pg"
  parameter_group_family                = "postgres13.4"
  parameters = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
    },
    {
      name  = "slow_query_log"
      value = "1"
    }
  ]
}

module "eb_app" {
  source          = "./modules/elastic_beanstalk"
  app_name        = var.app_name
  app_description = "Production application for ${var.app_name}"
  environments = [
    {
      name                = "${var.app_name}-prod"
      solution_stack_name = "64bit Amazon Linux 2 v3.4.5 running Docker"
      settings = [
        {
          namespace = "aws:ec2:vpc"
          name      = "VPCId"
          value     = module.vpc.vpc.id
        },

        {
          namespace = "aws:ec2:vpc"
          name      = "Subnets"
          value     = join(",", module.public_subnets.subnets[*].id)
        },
        {
          namespace = "aws:ec2:vpc"
          name      = "ELBSubnets"
          value     = join(",", module.public_subnets.subnets[*].id)
        },

        {
          namespace = "aws:autoscaling:launchconfiguration"
          name      = "IamInstanceProfile"
          value     = "aws-elasticbeanstalk-ec2-role"
        },

        {
          namespace = "aws:autoscaling:launchconfiguration"
          name      = "InstanceType"
          value     = var.instance_type
        },
        {
          namespace = "aws:autoscaling:asg"
          name      = "MinSize"
          value     = var.min_instances
        },

        {
          namespace = "aws:autoscaling:asg"
          name      = "MaxSize"
          value     = var.max_instances
        },

        {
          namespace = "aws:elasticbeanstalk:environment"
          name      = "EnvironmentType"
          value     = "LoadBalanced"
        },
        {
          namespace = "aws:elasticbeanstalk:environment"
          name      = "LoadBalancerType"
          value     = "application"
        },

        {
          namespace = "aws:elasticbeanstalk:healthreporting:system"
          name      = "SystemType"
          value     = "enhanced"
        },

        {
          namespace = "aws:elasticbeanstalk:command"
          name      = "DeploymentPolicy"
          value     = "Rolling"
        },

        {
          namespace = "aws:elasticbeanstalk:command"
          name      = "BatchSizeType"
          value     = "Percentage"
        },

        {
          namespace = "aws:elasticbeanstalk:command"
          name      = "BatchSize"
          value     = "50"
        },

        {
          namespace = "aws:elasticbeanstalk:command"
          name      = "IgnoreHealthCheck"
          value     = "false"
        },

        # Environment variables (including DB connection)
        {
          namespace = "aws:elasticbeanstalk:application:environment"
          name      = "DATABASE_URL"
          value     = "postgresql://${var.db_username}:${var.db_password}@${module.db.endpoint}/${var.db_name}"
        },
        {
          namespace = "aws:elasticbeanstalk:application:environment"
          name      = "ENVIRONMENT"
          value     = "production"
        }

      ]
    }
  ]
}