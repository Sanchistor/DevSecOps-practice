terraform {
  backend "s3" {
    bucket = "tf-resources-state-bucket"
    key    = "deployment_state/terraform_state.tfstate"
    region = "eu-west-1"
  }
}