resource "aws_ecs_cluster" "app" {
    name = var.cluster-name
}

resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "image": "${var.app_image}:${var.app_tag}",
    "memory": 512,
    "name": "app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "main" {
  name = "tf-ecs-service"
  cluster = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 2
  launch_type = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.internal.id]
    subnets = aws_subnet.private_subnet.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app_tg.id
    container_name   = "app"
    container_port   = 80
  }
  depends_on = [aws_alb.instance_alb]
}
