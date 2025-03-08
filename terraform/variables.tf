variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "tag-name" {
  default = "jenkins"
}

variable "app_name" {
  type    = string
  default = "my-app-ecr"
}

// Database Config
variable "database_name"{
    type = string
    default = "myappdb"
}

variable "db-username" {
  type    = string
  default = "username" #move to ssm
}

variable "db-password" {
  type    = string
  default = "123456789" #move to ssm
}

//EKS config
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "MYAPP-EKS"
}

# variable "vpc_id" {
#   description = "VPC used by EKS"
#   type        = string
#   default     = "vpc-05af5b6e232a44102"
# }

# variable "subnet_id" {
#   description = "Subnet used by EKS"
#   type        = string
#   default     = "subnet-0dcaac22cc39d0da7"
# }