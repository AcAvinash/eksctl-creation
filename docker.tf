resource "aws_key_pair" "tf_key" {
  key_name   = "my-tf-key"
  public_key = file("../terraform.pub")
}

resource "aws_instance" "docker" {
  ami           = "ami-0157af9aea2eef346"
  #instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.allow_all_docker.id]
  instance_type = "t3.medium"
   key_name                    = aws_key_pair.tf_key.key_name
  # need more for terraform
  root_block_device {
    volume_size = 50
    volume_type = "gp3" # or "gp2", depending on your preference
  }
  user_data = file("docker.sh")
  #iam_instance_profile = "TerraformAdmin"
  tags = {
     Name = "${var.project}-${var.environment}-docker"
  }
}

resource "aws_security_group" "allow_all_docker" {
    name        = "allow_all_docker"
    description = "allow all traffic"

    ingress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    lifecycle {
      create_before_destroy = true
    }

    tags = {
        Name = "allow-all-docker"
    }
}