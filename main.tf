provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "az" {
  for_each          = toset(["us-east-1a", "us-east-1b"])
  availability_zone = each.key
}

resource "aws_security_group" "web" {
  name   = "amazon-web-sg"
  vpc_id = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_module" {
  for_each      = toset(["us-east-1a", "us-east-1b"])
  ami           = "ami-01edba92f9036f76e"
  instance_type = "t3.micro"

  subnet_id              = aws_default_subnet.az[each.key].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo yum install httpd git -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo git clone https://github.com/Ironhack-Archive/online-clone-amazon.git
    sudo mv online-clone-amazon/* /var/www/html
  EOF

  tags = {
    Name = "ec2-module-${each.key}"
  }
}

resource "aws_lb" "app" {
  name            = "amazon-alb"
  security_groups = [aws_security_group.web.id]
  subnets = [
    aws_default_subnet.az["us-east-1a"].id,
    aws_default_subnet.az["us-east-1b"].id,
  ]
}

resource "aws_lb_target_group" "app" {
  name     = "amazon-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_target_group_attachment" "app" { #registered target group for ec2 instances
  for_each         = aws_instance.ec2_module
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.value.id
  port             = 80
}

resource "aws_lb_listener" "app" { #listeners and routing (forwards traffic to target group)
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}
