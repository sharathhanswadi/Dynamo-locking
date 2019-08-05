

remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-sharath"
    key            = "/home/ubuntu/terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }   

