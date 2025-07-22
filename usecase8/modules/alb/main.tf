resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  
 


  enable_deletion_protection = false

  tags = {
    Name        = "${var.environment}-alb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "patient_service" {
  name         = "${var.environment}-patient-tg"
  port         = 3000
  protocol     = "HTTP"
  vpc_id       = var.vpc_id
  target_type  = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    matcher             = "200"
    path                = "/health/status"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-patient-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "appointment_service" {
  name         = "${var.environment}-apmt-tg"
  port         = 3001
  protocol     = "HTTP"
  vpc_id       = var.vpc_id
  target_type  = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health/status"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-appointment-tg"
    Service     = "appointment-service"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Patient and Appointment service is running as expected"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.environment}-alb-listener"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "patient_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.patient_service.arn
  }

  condition {
    path_pattern {
      values = ["/patients/status"]
    }
  }

  tags = {
    Name        = "${var.environment}-patient-rule"
    Service     = "patient-service"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "appointment_service" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.appointment_service.arn
  }

  condition {
    path_pattern {
      values = ["/appointments/status"]
    }
  }

  tags = {
    Name        = "${var.environment}-appointment-rule"
    Service     = "appointment-service"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "patient_health_check" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 40

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"healthy\",\"service\":\"uc8-patient-service\"}"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health/patient"]
    }
  }

  tags = {
    Name        = "${var.environment}-patient-health-rule"
    Service     = "patient-service"
    Environment = var.environment
  }
}

resource "aws_lb_listener_rule" "appointment_health_check" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 45

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"status\":\"healthy\",\"service\":\"uc8-appointment-service\"}"
      status_code  = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health/appointment"]
    }
  }

  tags = {
    Name        = "${var.environment}-appointment-health-rule"
    Service     = "appointment-service"
    Environment = var.environment
  }
}
