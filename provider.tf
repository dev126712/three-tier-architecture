provider "aws" {
  region = var.aws_region

}
data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"
  alias  = "source_region"
}

provider "aws" {
  region = "us-west-2"
  alias  = "destination_region"
}