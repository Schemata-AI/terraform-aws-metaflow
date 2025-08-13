data "aws_iam_policy_document" "ecs_execution_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com",
        "batch.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

# Create wrapper role that assumes the shared ECS execution role when using existing role
resource "aws_iam_role" "ecs_execution_wrapper_role" {
  count = var.existing_ecs_execution_role_name != "" ? 1 : 0
  name = "${var.resource_prefix}ecs-execution-wrapper-role${var.resource_suffix}"
  description = "Wrapper role that assumes the shared ECS execution role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_role.json

  tags = var.standard_tags
}

resource "aws_iam_role_policy" "assume_shared_ecs_execution_role" {
  count = var.existing_ecs_execution_role_name != "" ? 1 : 0
  name = "assume-shared-execution-role"
  role = aws_iam_role.ecs_execution_wrapper_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:${var.iam_partition}:iam::${var.shared_iam_account_id}:role/${var.existing_ecs_execution_role_name}"
      }
    ]
  })
}

# Add CloudWatch Logs permissions to the wrapper role for ECS execution
resource "aws_iam_role_policy" "wrapper_role_ecs_execution_permissions" {
  count = var.existing_ecs_execution_role_name != "" ? 1 : 0
  name = "ecs-execution-permissions"
  role = aws_iam_role.ecs_execution_wrapper_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Original ECS execution role for when not using existing role
resource "aws_iam_role" "ecs_execution_role" {
  count = var.existing_ecs_execution_role_name == "" ? 1 : 0
  name = local.ecs_execution_role_name
  description = "This role is passed to our AWS ECS' task definition as the `execution_role`. This allows things like the correct image to be pulled and logs to be stored."
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_assume_role.json

  tags = var.standard_tags
}

# Note: We construct the ARN directly in locals.tf instead of using data source
# because the role exists in a different AWS account (shared_iam_account_id)

data "aws_iam_policy_document" "ecs_task_execution_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    # The `"Resource": "*"` is not a concern and the policy that Amazon suggests using
    # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "grant_ecs_access" {
  count  = var.existing_ecs_execution_role_name == "" ? 1 : 0
  name   = "ecs_access"
  role   = local.ecs_execution_role_name_actual
  policy = data.aws_iam_policy_document.ecs_task_execution_policy.json
}
