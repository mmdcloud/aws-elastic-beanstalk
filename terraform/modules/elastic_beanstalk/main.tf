# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = var.app_description
}

# Elastic Beanstalk Environment
resource "aws_elastic_beanstalk_environment" "env" {
  count               = length(var.environments)
  name                = var.environments[count.index].name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = var.environments[count.index].solution_stack_name
  dynamic "setting" {
    for_each = var.environments[count.index].settings
    content {
      namespace = each.value.namespace
      name      = each.value.name
      value     = each.value.value
    }
  }
  tags = {
    Environment = "production"
  }
}