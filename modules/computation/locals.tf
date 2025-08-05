locals {
  # Name of Batch service's security group used on the compute environment
  batch_security_group_name = "${var.resource_prefix}batch-compute-environment-security-group${var.resource_suffix}"

  # Prefix name of Batch compute environment
  compute_env_prefix_name = "${var.resource_prefix}cpu${var.resource_suffix}"

  # Name of Batch Queue.
  # replace() ensures names that are composed of just prefix + suffix do not have duplicate dashes
  batch_queue_name = replace("${var.resource_prefix}${var.resource_suffix}", "--", "-")

  # Name of IAM role to create to manage ECS tasks
  ecs_execution_role_name = "${var.resource_prefix}ecs-execution-role${var.resource_suffix}"

  # Name of Batch service IAM role
  batch_execution_role_name = "${var.resource_prefix}batch-execution-role${var.resource_suffix}"

  # Name of ECS IAM role
  ecs_instance_role_name = "${var.resource_prefix}ecs-iam-role${var.resource_suffix}"

  enable_fargate_on_batch = var.batch_type == "fargate"
  
  # Reference to the ECS execution role (either existing or created)
  ecs_execution_role_name_actual = var.existing_ecs_execution_role_name != "" ? data.aws_iam_role.existing_ecs_execution_role[0].name : aws_iam_role.ecs_execution_role[0].name
  ecs_execution_role_arn_actual = var.existing_ecs_execution_role_name != "" ? data.aws_iam_role.existing_ecs_execution_role[0].arn : aws_iam_role.ecs_execution_role[0].arn
}
