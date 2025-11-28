terraform {
  backend "s3" {
    bucket         = "sweetdream-terraform-state-409964509537"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "sweetdream-terraform-locks"
  }
}
