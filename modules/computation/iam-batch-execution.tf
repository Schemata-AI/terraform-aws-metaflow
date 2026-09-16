data "aws_iam_policy_document" "batch_execution_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = [
        "batch.amazonaws.com",
      ]
      type = "Service"
    }
  }
}

# Create wrapper role for Batch execution when using existing cross-account role
resource "aws_iam_role" "batch_execution_wrapper_role" {
  count = var.existing_batch_execution_role_name != "" ? 1 : 0
  name = "${var.resource_prefix}batch-execution-wrapper-role${var.resource_suffix}"
  description = "Wrapper role with AWS Batch service permissions (uses AWSBatchServiceRole managed policy)"
  assume_role_policy = data.aws_iam_policy_document.batch_execution_role_assume_role.json

  tags = var.standard_tags
}

# Attach AWS managed policy for Batch service role
resource "aws_iam_role_policy_attachment" "batch_wrapper_service_role" {
  count = var.existing_batch_execution_role_name != "" ? 1 : 0
  role = aws_iam_role.batch_execution_wrapper_role[0].name
  policy_arn = "arn:${var.iam_partition}:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Original Batch execution role for when not using existing role
resource "aws_iam_role" "batch_execution_role" {
  count = var.existing_batch_execution_role_name == "" ? 1 : 0
  name = local.batch_execution_role_name
  description = "This role is passed to AWS Batch as a `service_role`. This allows AWS Batch to make calls to other AWS services on our behalf."
  assume_role_policy = data.aws_iam_policy_document.batch_execution_role_assume_role.json

  tags = var.standard_tags
}

# Note: We construct the ARN directly instead of using data source for existing roles
# because the role exists in a different AWS account (shared_iam_account_id)

data "aws_iam_policy_document" "iam_pass_role" {
  statement {
    actions = [
      "iam:PassRole"
    ]

    effect = "Allow"

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "ec2.amazonaws.com.cn", "ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "custom_access_policy" {
  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeImages",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotFleetInstances",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:CreateLaunchTemplate",
      "ec2:DeleteLaunchTemplate",
      "ec2:RequestSpotFleet",
      "ec2:CancelSpotFleetRequests",
      "ec2:ModifySpotFleetRequest",
      "ec2:TerminateInstances",
      "ec2:RunInstances",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:SuspendProcesses",
      "autoscaling:PutNotificationConfiguration",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ecs:DescribeClusters",
      "ecs:DescribeContainerInstances",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListClusters",
      "ecs:ListContainerInstances",
      "ecs:ListTaskDefinitionFamilies",
      "ecs:ListTaskDefinitions",
      "ecs:ListTasks",
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:UpdateContainerAgent",
      "ecs:DeregisterContainerInstance",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "iam:GetInstanceProfile",
      "iam:GetRole",
    ]

    effect = "Allow"

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "iam_custom_policies" {
  statement {
    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    effect = "Allow"

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["autoscaling.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_custom_policies" {
  statement {
    actions = [
      "ec2:CreateTags"
    ]

    effect = "Allow"

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances"]
    }
  }
}

resource "aws_iam_role_policy" "grant_iam_pass_role" {
  count  = var.existing_batch_execution_role_name == "" ? 1 : 0
  name   = "iam_pass_role"
  role   = local.batch_execution_role_name_actual
  policy = data.aws_iam_policy_document.iam_pass_role.json
}

resource "aws_iam_role_policy" "grant_custom_access_policy" {
  count  = var.existing_batch_execution_role_name == "" ? 1 : 0
  name   = "custom_access"
  role   = local.batch_execution_role_name_actual
  policy = data.aws_iam_policy_document.custom_access_policy.json
}

resource "aws_iam_role_policy" "grant_iam_custom_policies" {
  count  = var.existing_batch_execution_role_name == "" ? 1 : 0
  name   = "iam_custom"
  role   = local.batch_execution_role_name_actual
  policy = data.aws_iam_policy_document.iam_custom_policies.json
}

resource "aws_iam_role_policy" "grant_ec2_custom_policies" {
  count  = var.existing_batch_execution_role_name == "" ? 1 : 0
  name   = "ec2_custom"
  role   = local.batch_execution_role_name_actual
  policy = data.aws_iam_policy_document.ec2_custom_policies.json
}
