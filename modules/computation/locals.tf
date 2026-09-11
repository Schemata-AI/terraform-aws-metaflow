locals {
  # Name of Batch service's security group used on the compute environment
  batch_security_group_name = "${var.resource_prefix}batch-compute-environment-security-group${var.resource_suffix}"

  # Prefix name of Batch compute environment (GPU/default)
  compute_env_prefix_name = "${var.resource_prefix}cpu${var.resource_suffix}"

  # Prefix name of CPU-only Batch compute environment
  cpu_compute_env_prefix_name = "${var.resource_prefix}cpu-only${var.resource_suffix}"

  # Name of Batch Queue (GPU/default).
  # replace() ensures names that are composed of just prefix + suffix do not have duplicate dashes
  batch_queue_name = replace("${var.resource_prefix}${var.resource_suffix}", "--", "-")

  # Name of CPU-only Batch Queue
  cpu_batch_queue_name = replace("${var.resource_prefix}cpu${var.resource_suffix}", "--", "-")

  # Fair-share queues (Tessera Step Functions). FIFO queues above stay unchanged.
  fairshare_policy_name          = replace("${var.resource_prefix}fairshare-policy${var.resource_suffix}", "--", "-")
  fairshare_batch_queue_name     = replace("${var.resource_prefix}fairshare${var.resource_suffix}", "--", "-")
  cpu_fairshare_batch_queue_name = replace("${var.resource_prefix}cpu-fairshare${var.resource_suffix}", "--", "-")

  # Name of IAM role to create to manage ECS tasks
  ecs_execution_role_name = "${var.resource_prefix}ecs-execution-role${var.resource_suffix}"

  # Name of Batch service IAM role
  batch_execution_role_name = "${var.resource_prefix}batch-execution-role${var.resource_suffix}"

  # Name of ECS IAM role
  ecs_instance_role_name = "${var.resource_prefix}ecs-iam-role${var.resource_suffix}"

  enable_fargate_on_batch = var.batch_type == "fargate"

  # Shared Tessera fair-share queues live only in the development Batch account.
  enable_fairshare_job_queues = lookup(var.standard_tags, "env", "") == "development"
}
