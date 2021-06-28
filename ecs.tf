data "aws_ami" "ecs" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = [
    "amzn-ami-*-ecs-optimized"] # ECS optimized image
  }

  filter {
    name = "virtualization-type"
    values = [
    "hvm"]
  }

  owners = [
    "amazon" # Only official images
  ]
}

resource "aws_iam_service_linked_role" "ecs" {
  aws_service_name = "ecs.amazonaws.com"
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name                 = "${var.app_name}-launch-config"
  image_id             = data.aws_ami.ecs.id
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [module.ecs_security_group.security_group_id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=ecs-cluster >> /etc/ecs/ecs.config"
  instance_type        = "t2.micro"
  key_name             = "laptop"
}

resource "aws_autoscaling_group" "failure_analysis_ecs_asg" {
  name                 = "${var.app_name}-asg"
  vpc_zone_identifier  = module.vpc.public_subnets
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"

  depends_on = [aws_launch_configuration.ecs_launch_config]
}

resource "aws_ecs_capacity_provider" "asg_capacity_provider" {
  name = "asg-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.failure_analysis_ecs_asg.arn
  }

  depends_on = [aws_iam_service_linked_role.ecs]
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  capacity_providers = [aws_ecs_capacity_provider.asg_capacity_provider.name]
  depends_on         = [aws_ecs_capacity_provider.asg_capacity_provider]

  tags = {
    "app" = var.app_name
  }

  # We need to terminate all instances before the cluster can be destroyed.
  # (Terraform would handle this automatically if the autoscaling group depended
  #  on the cluster, but we need to have the dependency in the reverse
  #  direction due to the capacity_providers field above).
  provisioner "local-exec" {
    when = destroy

    command = <<CMD
      # Get the list of capacity providers associated with this cluster
      REGION=eu-central-1
      CAP_PROVS="$(aws ecs describe-clusters --clusters "${self.arn}" \
        --query 'clusters[*].capacityProviders[*]' \
        --region "$REGION" --output text)"

      # Now get the list of autoscaling groups from those capacity providers
      ASG_ARNS="$(aws ecs describe-capacity-providers \
        --capacity-providers "$CAP_PROVS" \
        --query 'capacityProviders[*].autoScalingGroupProvider.autoScalingGroupArn' \
        --region "$REGION" --output text)"

      if [ -n "$ASG_ARNS" ] && [ "$ASG_ARNS" != "None" ]
      then
        for ASG_ARN in $ASG_ARNS
        do
          ASG_NAME=$(echo $ASG_ARN | cut -d/ -f2-)

          # Set the autoscaling group size to zero
          aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name "$ASG_NAME" \
            --min-size 0 --max-size 0 --desired-capacity 0\
            --region "$REGION"

          # Remove scale-in protection from all instances in the asg
          INSTANCES="$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names "$ASG_NAME" \
            --query 'AutoScalingGroups[*].Instances[*].InstanceId' \
            --region "$REGION" --output text)"
          aws autoscaling set-instance-protection --instance-ids $INSTANCES \
            --auto-scaling-group-name "$ASG_NAME" \
            --region "$REGION" --no-protected-from-scale-in
        done
      fi
CMD
  }
}

data "aws_instances" "ecs_instances_meta" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.failure_analysis_ecs_asg.name
  }
}
