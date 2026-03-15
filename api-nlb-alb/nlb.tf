resource "aws_lb_listener" "nlb_tcp" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb.arn
  }
}

resource "aws_lb" "nlb" {
  name               = substr("${local.name}-nlb", 0, 32)
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${local.name}-nlb"
  }
}
