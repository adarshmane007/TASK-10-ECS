provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "adarsh_subnet_999a" {
  id = "subnet-03e1b3fe2ad999849"
}

data "aws_subnet" "adarsh_subnet_999b" {
  id = "subnet-05e9035d969355719"
}

data "aws_security_group" "adarsh_sg_999" {
  id = "sg-05107eda1fad1280d"
}

resource "aws_ecs_cluster" "adarsh_cluster_999" {
  name = "adarsh-strapi-cluster-999"
}

resource "aws_lb" "adarsh_alb_spot_999" {
  name               = "adarsh-strapi-alb-spot-999"
  internal           = false
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.adarsh_subnet_999a.id, data.aws_subnet.adarsh_subnet_999b.id]
  security_groups    = [data.aws_security_group.adarsh_sg_999.id]
}

resource "aws_lb_target_group" "adarsh_tg_spot_999" {
  name        = "adarsh-strapi-tg-spot-999"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "adarsh_listener_spot_999" {
  load_balancer_arn = aws_lb.adarsh_alb_spot_999.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.adarsh_tg_spot_999.arn
  }
}

resource "aws_cloudwatch_log_group" "strapi_logs_999" {
  name              = "/ecs/strapi-spot-999"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

resource "aws_ecs_task_definition" "adarsh_task_999" {
  family                   = "adarsh-strapi-task-999"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = "arn:aws:iam::145065858967:role/adarshecsrole"

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.ecr_image_url
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "API_TOKEN_SALT", value = "j4rqpdb/U8JdU+aubTSBmQ==" },
        { name = "ADMIN_JWT_SECRET", value = "rGNuU8jxCYxmVxQrTcPPFrNg7ue/1L4mNc8wzVXEyiQ=" },
        { name = "TRANSFER_TOKEN_SALT", value = "RqkOPXvmnN+3ONyuc78XsxetlLSsMilqi93HA1U/GHE=" },
        { name = "ENCRYPTION_KEY", value = "joKNsWCuXj0DgjRfSm6TCjGQp8vCnIylKK4k9g97x5Q=" },
        { name = "HOST", value = "0.0.0.0" },
        { name = "PORT", value = tostring(var.container_port) }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.strapi_logs_999.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "adarsh_service_spot_999" {
  name            = "adarsh-strapi-service-spot-999"
  cluster         = aws_ecs_cluster.adarsh_cluster_999.id
  task_definition = aws_ecs_task_definition.adarsh_task_999.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets          = [data.aws_subnet.adarsh_subnet_999a.id, data.aws_subnet.adarsh_subnet_999b.id]
    security_groups  = [data.aws_security_group.adarsh_sg_999.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.adarsh_tg_spot_999.arn
    container_name   = "strapi"
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 120

  depends_on = [aws_lb_listener.adarsh_listener_spot_999]
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm_999" {
  alarm_name          = "high-cpu-usage-task-999"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm when CPU usage exceeds 80%"
  dimensions = {
    ClusterName = aws_ecs_cluster.adarsh_cluster_999.name
    ServiceName = aws_ecs_service.adarsh_service_spot_999.name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_memory_alarm_999" {
  alarm_name          = "high-memory-usage-task-999"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 77
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm when memory usage exceeds 77%"
  dimensions = {
    ClusterName = aws_ecs_cluster.adarsh_cluster_999.name
    ServiceName = aws_ecs_service.adarsh_service_spot_999.name
  }
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard_999" {
  dashboard_name = "ecs-strapi-task-999-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width  = 12,
        height = 6,
        properties = {
          title  = "ECS CPU & Memory Usage",
          region = var.region,
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.adarsh_cluster_999.name, "ServiceName", aws_ecs_service.adarsh_service_spot_999.name ],
            [ "AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.adarsh_cluster_999.name, "ServiceName", aws_ecs_service.adarsh_service_spot_999.name ]
          ],
          stat = "Average",
          period = 60
        }
      }
    ]
  })
}
