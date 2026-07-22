variable "vpc_id" {
  description = "VPC ID the RDS instance and its security group live in"
  type        = string
}

variable "private_subnet_1_id" {
  description = "First private subnet ID for the DB subnet group"
  type        = string
}

variable "private_subnet_2_id" {
  description = "Second private subnet ID for the DB subnet group"
  type        = string
}

variable "web_sg_id" {
  description = "Security group ID of the app/web tier allowed to reach the database"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}
