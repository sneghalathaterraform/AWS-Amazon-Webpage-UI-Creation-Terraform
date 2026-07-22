resource "aws_db_subnet_group" "main" {
  name       = "assignment1-db-subnet-group"
  subnet_ids = [var.private_subnet_1_id, var.private_subnet_2_id]

  tags = {
    Name = "assignment1-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name   = "assignment1-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "MySQL access from the web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.web_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "assignment1-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "assignment1-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = "assignment1"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "assignment1-db"
  }
}
