locals {
  dynamodb_step_functions_state_db_name = "${var.resource_prefix}step_functions_state${var.resource_suffix}"
  
  # Reference to the EventBridge role (either existing or created)
  eventbridge_role_name_actual = var.existing_eventbridge_role_name != "" ? var.existing_eventbridge_role_name : aws_iam_role.eventbridge_role[0].name
  eventbridge_role_arn_actual = var.existing_eventbridge_role_name != "" ? "arn:${var.iam_partition}:iam::${var.shared_iam_account_id}:role/${var.existing_eventbridge_role_name}" : aws_iam_role.eventbridge_role[0].arn
  
  # Reference to the Step Functions role (either existing or created)
  step_functions_role_name_actual = var.existing_step_functions_role_name != "" ? var.existing_step_functions_role_name : aws_iam_role.step_functions_role[0].name
  step_functions_role_arn_actual = var.existing_step_functions_role_name != "" ? "arn:${var.iam_partition}:iam::${var.shared_iam_account_id}:role/${var.existing_step_functions_role_name}" : aws_iam_role.step_functions_role[0].arn
}
