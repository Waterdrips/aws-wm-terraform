resource "aws_alb" "instance_alb" {
  name = "${var.environment_name}-alb"
  internal = false

  security_groups = [
    aws_security_group.internal.id,
    aws_security_group.external.id,
  ]
  subnets = aws_subnet.public_subnet.*.id
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.instance_alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app_tg.arn
    type = "forward"

  }

  depends_on = ["aws_alb_target_group.app_tg"]
}

resource "aws_alb_target_group" "app_tg" {
  name = "${var.environment_name}-app-instance-tg1"
  protocol = "HTTP"
  target_type = "ip"
  port = var.app_container_port
  vpc_id = aws_vpc.vpc.id

  health_check {
    protocol = "HTTP"
    path = "/"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    matcher = 200
  }

  stickiness {
    type = "lb_cookie"
    cookie_duration = 1
    enabled = false
  }
  lifecycle { create_before_destroy = true }
}


output "dns_name" {
  value = aws_alb.instance_alb.dns_name
}