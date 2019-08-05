provider "aws" {
  region = "us-east-1"
}







data "template_file" "user_data" {
template = "${file("${path.module}/user-data.sh")}"
vars = {
server_port = "${var.server_port}"
db_address = "${data.terraform_remote_state.db.address}"
db_port = "${data.terraform_remote_state.db.port}"


}
}



resource "aws_launch_configuration" "example" {
  image_id        = "ami-40d28157"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance.id]

  user_data ="${data.template_file.user_data.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "all" {
}










resource "aws_s3_bucket" "terraform_sharath" {
  bucket = "terraform-sharath"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}



data "terraform_remote_state" "db" {
backend = "s3"
config =  {
bucket = "terraform-sharath"
key = "global/s3/terraform.tfstate"
region = "us-east-1"
}
}





resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
attribute {
    name = "LockID"
    type = "S"
  }
}


terraform {
  backend "s3" {
    bucket = "terraform-sharath"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-lock"
  }
}




 



resource "aws_elb" "example" {
  name = "terraform-asg-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups = [aws_security_group.elb.id]
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = var.server_port
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.id
  availability_zones = data.aws_availability_zones.all.names
  load_balancers = [aws_elb.example.name]
  health_check_type = "ELB"
  min_size = 2
  max_size = 10
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

output "elb_dns_name" {
  value = aws_launch_configuration.example.instance_type
}

output "s3_bucket_name" {
  value = aws_s3_bucket.terraform_sharath.arn
}

