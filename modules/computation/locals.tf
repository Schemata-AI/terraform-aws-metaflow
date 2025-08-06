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
  
  # Reference to the ECS execution role (use wrapper role when cross-account, otherwise local role)
  ecs_execution_role_name_actual = var.existing_ecs_execution_role_name != "" ? aws_iam_role.ecs_execution_wrapper_role[0].name : aws_iam_role.ecs_execution_role[0].name
  ecs_execution_role_arn_actual = var.existing_ecs_execution_role_name != "" ? aws_iam_role.ecs_execution_wrapper_role[0].arn : aws_iam_role.ecs_execution_role[0].arn
  
  # Reference to the batch execution role (use wrapper role when cross-account, otherwise local role)
  batch_execution_role_name_actual = var.existing_batch_execution_role_name != "" ? aws_iam_role.batch_execution_wrapper_role[0].name : aws_iam_role.batch_execution_role[0].name
  batch_execution_role_arn_actual = var.existing_batch_execution_role_name != "" ? aws_iam_role.batch_execution_wrapper_role[0].arn : aws_iam_role.batch_execution_role[0].arn
  
  # Reference to the ECS instance role (wrapper role in deployment account)
  ecs_instance_role_name_actual = aws_iam_role.ecs_instance_wrapper_role.name
  ecs_instance_role_arn_actual = aws_iam_role.ecs_instance_wrapper_role.arn
  
  # Reference to the instance profile (either existing or created)
  ecs_instance_profile_name_actual = var.existing_ecs_instance_profile_name != "" ? var.existing_ecs_instance_profile_name : local.ecs_instance_role_name
  ecs_instance_profile_arn_actual = var.existing_ecs_instance_profile_name != "" ? "arn:${var.iam_partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.existing_ecs_instance_profile_name}" : aws_iam_instance_profile.ecs_instance_role[0].arn
}
