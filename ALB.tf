resource "aws_lb" "alb_Drago_ro" {
  name               = "Drago-ro-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.lb_sg.id]

  subnets = [
    aws_subnet.subnet_public_1.id,
    aws_subnet.subnet_public_2.id
  ]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "alb_tg_Drago_ro" {
  name        = "app-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.Drago_ro.id
  target_type = "instance"

  health_check {
    protocol = "HTTPS"
    path     = "/"
    matcher  = "200"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.alb_tg_Drago_ro.arn
  target_id        = aws_instance.app.id
  port             = 8080
}

resource "aws_lb_listener" "https_Draco_ro" {
  load_balancer_arn = aws_lb.alb_Drago_ro.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg_Drago_ro.arn
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "alb-Drago-ro-sg"
  description = "Security Group for public ALB"
  vpc_id      = aws_vpc.Drago_ro.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.ec2_Draco_ro.id]
  }

  egress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.ec2_Draco_ro.id]
  }

  egress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.ec2_Draco_ro.id]
  }

  tags = {
    Name        = "sg-alb-Drago-ro"
    Environment = "production"
  }
}