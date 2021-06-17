resource "aws_cloudwatch_log_group" "cocktail_master" {
  name              = var.app_name
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "cocktail_master" {
  family = var.app_name

  depends_on = [aws_ecs_cluster.ecs_cluster, aws_db_instance.database]

  container_definitions = jsonencode([
    {
      "name" : "${var.app_name}",
      "image" : "${var.repo_url}:${var.image_tag}",
      "command" : ["gunicorn", "${var.app_name}.wsgi:application",
      "--bind", "0.0.0.0:8000", "--access-logfile", "'-'"],
      "memory" : 128,
      "environment" : [
        { "name" : "DB_ENGINE", "value" : "django.db.backends.postgresql_psycopg2" },
        { "name" : "DB_HOST", "value" : "${aws_db_instance.database.address}" },
        { "name" : "DB_PORT", "value" : "5432" },
        { "name" : "DB_NAME", "value" : "${var.app_name}" },
        { "name" : "DB_USER", "value" : "${var.db_username}" },
        { "name" : "DB_PASSWORD", "value" : "${var.db_password}" },
        { "name" : "DJANGO_SECRET_KEY", "value" : "${var.django_key}" }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "${var.aws_region}",
          "awslogs-group" : "${var.app_name}",
          "awslogs-stream-prefix" : "${var.app_name}"
        }
      }
      "portMappings" : [{
        "containerPort" : 8000,
        "hostPort" : 80
      }],
    }
  ])
}

resource "aws_ecs_service" "cocktail_master" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.cocktail_master.arn

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
}
