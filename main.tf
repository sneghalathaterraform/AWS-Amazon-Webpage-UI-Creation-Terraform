provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "./modules/vpc"
}

resource "aws_security_group" "web" {
  name   = "amazon-web-sg"
  vpc_id = module.vpc.vpc_id

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
resource "aws_launch_template" "web" {
  name_prefix   = "amazon-lt-"
  image_id      = "ami-01edba92f9036f76e"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum install httpd git -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo git clone https://github.com/Ironhack-Archive/online-clone-amazon.git
    sudo mv online-clone-amazon/* /var/www/html
  EOF
  )
}



resource "aws_lb" "app" {
  name            = "amazon-alb"
  security_groups = [aws_security_group.web.id]
  subnets = [
    module.vpc.public_subnet_1_id,
    module.vpc.public_subnet_2_id,
  ]
}

resource "aws_lb_target_group" "app" {
  name     = "amazon-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
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

resource "aws_autoscaling_group" "web" {
  name                = "amazon-asg"
  vpc_zone_identifier = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  tag {
    key                 = "Name"
    value               = "asg-web"
    propagate_at_launch = true
  }
}


module "rds" {
  source = "./modules/rds"

  vpc_id              = module.vpc.vpc_id
  private_subnet_1_id = module.vpc.private_subnet_1_id
  private_subnet_2_id = module.vpc.private_subnet_2_id
  web_sg_id           = aws_security_group.web.id

  db_username = var.db_username
  db_password = var.db_password
}

