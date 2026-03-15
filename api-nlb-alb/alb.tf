resource "aws_lb" "alb" {
  name               = substr("${local.name}-alb", 0, 32)
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${local.name}-alb"
  }
}

resource "aws_lb_target_group" "lambda" {
  name        = substr("${local.name}-lambda-tg", 0, 32)
  target_type = "lambda"
}

resource "aws_lb_target_group" "alb" {
  name        = substr("${local.name}-alb-tg", 0, 32)
  port        = 80
  protocol    = "TCP"
  target_type = "alb"
  vpc_id      = aws_vpc.this.id

  health_check {
    enabled  = true
    protocol = "HTTP"
    path     = "/"
    matcher  = "200"
  }
}

resource "aws_lb_target_group_attachment" "alb" {
  target_group_arn = aws_lb_target_group.alb.arn
  target_id        = aws_lb.alb.arn
  port             = 80
  depends_on = [
    aws_lb_listener.alb_http,
    aws_lb.alb
  ]
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = aws_lambda_function.backend.arn

  depends_on = [aws_lambda_permission.allow_alb]
}

resource "aws_lb_listener" "alb_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda.arn
  }
}

