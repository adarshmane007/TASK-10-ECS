terraform {
  backend "s3" {
    bucket         = "adarshstrapi10"
    key            = "ecs-strapi/task10/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "strapi_subnet_am_10a" {
  id = "subnet-03e1b3fe2ad999849"
}

data "aws_subnet" "strapi_subnet_am_10b" {
  id = "subnet-05e9035d969355719"
}

data "aws_security_group" "strapi_sg_am_10" {
  id = "sg-05107eda1fad1280d"
}

resource "aws_ecs_cluster" "strapi_cluster_am_10" {
  name = "strapi-cluster-am-10"
}

resource "aws_lb" "strapi_alb_am_10" {
  name               = "strapi-alb-am-10"
  internal           = false
  load_balancer_type = "application"
  subnets            = [
    data.aws_subnet.strapi_subnet_am_10a.id,
    data.aws_subnet.strapi_subnet_am_10b.id
  ]
  security_groups    = [data.aws_security_group.strapi_sg_am_10.id]
}

resource "aws_lb_target_group" "strapi_tg_am_10" {
  name        = "strapi-tg-am-10"
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

resource "aws_lb_target_group" "strapi_tg_am_10_green" {
  name        = "strapi-tg-am-10-green"
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

resource "aws_lb_listener" "strapi_listener_am_10" {
  load_balancer_arn = aws_lb.strapi_alb_am_10.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg_am_10.arn
  }
}

resource "aws_ecs_task_definition" "strapi_task_am_10" {
  family                   = "strapi-task-am-10"
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
      ],
      environment = [
        { name = "API_TOKEN_SALT", value = "j4rqpdb/U8JdU+aubTSBmQ==" },
        { name = "ADMIN_JWT_SECRET", value = "rGNuU8jxCYxmVxQrTcPPFrNg7ue/1L4mNc8wzVXEyiQ=" },
        { name = "TRANSFER_TOKEN_SALT", value = "RqkOPXvmnN+3ONyuc78XsxetlLSsMilqi93HA1U/GHE=" },
        { name = "ENCRYPTION_KEY", value = "joKNsWCuXj0DgjRfSm6TCjGQp8vCnIylKK4k9g97x5Q=" },
        { name = "HOST", value = "0.0.0.0" },
        { name = "PORT", value = tostring(var.container_port) }
      ]
    }
  ])
}

resource "aws_ecs_service" "strapi_service_am_10" {
  name            = "strapi-service-am-10"
  cluster         = aws_ecs_cluster.strapi_cluster_am_10.id
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = [
      data.aws_subnet.strapi_subnet_am_10a.id,
      data.aws_subnet.strapi_subnet_am_10b.id
    ]
    security_groups  = [data.aws_security_group.strapi_sg_am_10.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_tg_am_10.arn
    container_name   = "strapi"
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 120

  depends_on = [aws_lb_listener.strapi_listener_am_10]
}

resource "aws_codedeploy_app" "strapi_app" {
  name              = "strapi-codedeploy-app"
  compute_platform  = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_group" {
  app_name              = aws_codedeploy_app.strapi_app.name
  deployment_group_name = "strapi-bluegreen-group"
  service_role_arn      = "arn:aws:iam::145065858967:role/adarshecsrole"

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  deployment_style {
    deployment_type  = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster_am_10.name
    service_name = aws_ecs_service.strapi_service_am_10.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.strapi_listener_am_10.arn]
      }

      target_group {
        name = aws_lb_target_group.strapi_tg_am_10.name
      }

      target_group {
        name = aws_lb_target_group.strapi_tg_am_10_green.name
      }
    }
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }

    green_fleet_provisioning_option {
      action = "DISCOVER_EXISTING"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
