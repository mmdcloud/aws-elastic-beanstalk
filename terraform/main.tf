resource "aws_s3_bucket" "theplayer007_nodeapp" {
  bucket = "theplayer007-nodeapp"
}

resource "aws_s3_object" "nodeapp-object" {
  bucket = aws_s3_bucket.theplayer007_nodeapp.id
  key    = "nodeapp.zip"
  source = "./files/nodeapp.zip"
}

# VPC Creation
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "public subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "private subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "route table"
  }
}

resource "aws_route_table_association" "route_table_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.route_table.id
}

# Elastic Beanstalk Role
resource "aws_iam_role" "elasticbeanstalk-role" {
  name               = "elasticbeanstalk-role"
  assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "elasticbeanstalk.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }
    EOF
}

# # AppRunnerECRAccess policy attachment 
# resource "aws_iam_role_policy_attachment" "elasticbeanstalk-managed-updates-role-policy-attachment" {
#   role       = aws_iam_role.elasticbeanstalk-role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
# }

# # AppRunnerECRAccess policy attachment 
# resource "aws_iam_role_policy_attachment" "elasticbeanstalk-enhanced-health-role-policy-attachment" {
#   role       = aws_iam_role.elasticbeanstalk-role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
# }

# Create elastic beanstalk application
resource "aws_elastic_beanstalk_application" "nodeapp" {
  name        = "nodeapp"
  description = "nodeapp"
  appversion_lifecycle {
    delete_source_from_s3 = true
    service_role          = aws_iam_role.elasticbeanstalk-role.arn
  }
}

# Create elastic beanstalk Environment
resource "aws_elastic_beanstalk_environment" "beanstalkappenv" {
  name                = "nodeapp-env"
  application         = aws_elastic_beanstalk_application.nodeapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.2.1 running Node.js 20"
  tier                = "WebServer"
  
  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.vpc.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_role.elasticbeanstalk-role.arn
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = true
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.public_subnets[0].id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "public"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = jsonencode(["t2.micro","t3.micro"])
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "EnableSpot"
    value     = false
  }
  
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 1
  }
  
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 2
  }
}

resource "aws_elastic_beanstalk_application_version" "nodeapp_version" {
  name        = "nodeapp_version"
  application = aws_elastic_beanstalk_application.nodeapp.name
  description = "Node.js based application deployed on Elastic Beanstalk"
  bucket      = aws_s3_bucket.theplayer007_nodeapp.id
  key         = aws_s3_object.nodeapp-object.id
  depends_on = [ aws_s3_bucket.theplayer007_nodeapp ]
}