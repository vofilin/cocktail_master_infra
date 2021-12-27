resource "aws_lb_target_group" "cocktail_master" {
  name     = "cocktail-master-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    port                = 80
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200" # has to be HTTP 200 or fails
  }

}

resource "aws_lb" "cocktail_master" {
  name               = "cocktail-master-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.ecs_security_group.security_group_id]
  subnets            = module.vpc.public_subnets
}


resource "aws_lb_listener" "cocktail_master" {
  load_balancer_arn = aws_lb.cocktail_master.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cocktail_master.arn
  }
}
