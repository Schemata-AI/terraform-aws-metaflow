data "aws_iam_policy_document" "eventbridge_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "events.amazonaws.com"
      ]
      type = "Service"
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "eventbridge_step_functions_policy" {
  statement {
    actions = [
      "states:StartExecution"
    ]

    resources = [
      "arn:${var.iam_partition}:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"
    ]
  }
}

resource "aws_iam_role" "eventbridge_role" {
  count              = var.active && var.existing_eventbridge_role_name == "" ? 1 : 0
  name               = "${var.resource_prefix}eventbridge_role${var.resource_suffix}"
  description        = "IAM role for Amazon EventBridge to access AWS Step Functions."
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role_policy.json

  tags = var.standard_tags
}

# Note: We construct the ARN directly instead of using data source for existing roles
# because the role exists in a different AWS account (shared_iam_account_id)

resource "aws_iam_role_policy" "eventbridge_step_functions_policy" {
  count  = var.active && var.existing_eventbridge_role_name == "" ? 1 : 0
  name   = "step_functions"
  role   = local.eventbridge_role_name_actual
  policy = data.aws_iam_policy_document.eventbridge_step_functions_policy.json
}
