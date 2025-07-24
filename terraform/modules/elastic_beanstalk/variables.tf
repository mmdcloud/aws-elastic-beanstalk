variable "app_name" {
  description = "Application name"
  type        = string
}

variable "app_description" {
  description = "Application description"
  type        = string
}

variable "environments" {
  description = "List of environments for the Elastic Beanstalk application"
  type = list(object({
    name                = string
    solution_stack_name = string
    settings = list(object({
      namespace = string
      name      = string
      value     = string
    }))
  }))
  default = []
}
