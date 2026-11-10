resource "aws_db_subnet_group" "db_group_Drago_ro" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = [aws_subnet.subnet_prive_2.id, aws_subnet.subnet_prive_3.id]
}


resource "aws_db_instance" "MySQL" {
  allocated_storage           = 20
  db_subnet_group_name        = aws_db_subnet_group.db_group_Drago_ro.id
  engine                      = "mysql"
  engine_version              = "8.0"
  identifier                  = "${var.project_name}-db"
  instance_class              = "db.t3.micro"
  manage_master_user_password = true
  username                    = var.db_user
  db_name                     = "inventory"
  vpc_security_group_ids      = [aws_security_group.rds_Draco_ro.id]
  parameter_group_name        = aws_db_parameter_group.force_ssl.name
  skip_final_snapshot         = true
  storage_encrypted           = true
  backup_retention_period     = 1
}


resource "aws_db_parameter_group" "force_ssl" {
  name   = "prod-force-ssl"
  family = "mysql8.0"

  parameter {
    name  = "require_secure_transport"
    value = "1" # refuse les connexions non SSL
  }
}