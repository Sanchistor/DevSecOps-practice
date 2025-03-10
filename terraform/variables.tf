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

variable "subnet_cidrs" {
  description = "List of subnet CIDR blocks"
  type        = list(string)
  default     = [
    "172.31.16.0/20", # Subnet 1 CIDR block
    "172.31.32.0/20", # Subnet 2 CIDR block
    "172.31.0.0/20"  # Subnet 3 CIDR block
  ]
}

variable "admin_user" {
    description = "User to access Cluster from AWS console"
    type = string
    default = "arn:aws:iam::266735847393:user/admin"
}