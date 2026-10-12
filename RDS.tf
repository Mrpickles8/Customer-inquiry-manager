resource "aws_db_subnet_group" "db_group_Drago_ro" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = [aws_subnet.subnet_prive_1.id, aws_subnet.subnet_prive_2.id]
}


resource "aws_db_instance" "MySQL" {
  allocated_storage       = 20
  backup_retention_period = 7
  db_subnet_group_name    = aws_db_subnet_group.db_group_Drago_ro.id
  engine                  = "mysql"
  engine_version          = "8.0"
  identifier              = "${var.project_name}-db"
  instance_class          = "db.t3.micro"
  password                = var.db_password
  username                = var.db_user
  db_name                 = "inquiries"
  vpc_security_group_ids  = [aws_security_group.rds_Draco_ro.id]
  skip_final_snapshot     = true


  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_Draco_ro.arn
}

resource "aws_kms_key" "rds_Draco_ro" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
