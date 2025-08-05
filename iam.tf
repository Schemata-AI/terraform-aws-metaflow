data "aws_iam_policy_document" "batch_s3_task_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "batch_s3_task_role" {
  count = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name = local.batch_s3_task_role_name

  description = "Role for AWS Batch to Access Amazon S3 [METAFLOW_ECS_S3_ACCESS_IAM_ROLE]"

  assume_role_policy = data.aws_iam_policy_document.batch_s3_task_role_assume_role.json

  tags = var.tags
}

data "aws_iam_role" "existing_batch_s3_task_role" {
  count = var.existing_batch_s3_task_role_name != "" ? 1 : 0
  name  = var.existing_batch_s3_task_role_name
}

data "aws_iam_policy_document" "custom_s3_list_batch" {
  statement {
    sid = "BucketAccessBatch"
    actions = [
      "s3:ListBucket"
    ]

    effect = "Allow"

    resources = [
      module.metaflow-datastore.s3_bucket_arn
    ]
  }
}

data "aws_iam_policy_document" "custom_s3_batch" {
  statement {
    sid = "ObjectAccessBatch"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    effect = "Allow"

    resources = [
      "${module.metaflow-datastore.s3_bucket_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "s3_kms" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      module.metaflow-datastore.datastore_s3_bucket_kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "deny_presigned_batch" {
  statement {
    sid = "DenyPresignedBatch"
    actions = [
      "s3:*"
    ]

    effect = "Deny"

    resources = [
      "*",
    ]

    condition {
      test = "StringNotEquals"
      values = [
        "REST-HEADER"
      ]
      variable = "s3:authType"
    }
  }
}

data "aws_iam_policy_document" "allow_sagemaker" {
  statement {
    sid = "AllowSagemakerCreate"
    actions = [
      "sagemaker:CreateTrainingJob"
    ]

    effect = "Allow"

    resources = [
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:training-job/*",
    ]
  }

  statement {
    sid = "AllowSagemakerDescribe"
    actions = [
      "sagemaker:DescribeTrainingJob"
    ]

    effect = "Allow"

    resources = [
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:training-job/*",
    ]
  }

  statement {
    sid = "AllowSagemakerDeploy"
    actions = [
      "sagemaker:CreateModel",
      "sagemaker:CreateEndpointConfig",
      "sagemaker:CreateEndpoint",
      "sagemaker:DescribeModel",
      "sagemaker:DescribeEndpoint",
      "sagemaker:InvokeEndpoint"
    ]

    effect = "Allow"

    resources = [
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:endpoint/*",
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:model/*",
      "arn:${var.iam_partition}:sagemaker:${local.aws_region}:${local.aws_account_id}:endpoint-config/*",
    ]
  }
}

data "aws_iam_policy_document" "iam_pass_role" {
  statement {
    sid = "AllowPassRole"
    actions = [
      "iam:PassRole",
    ]

    effect = "Allow"

    resources = [
      "*"
    ]

    condition {
      test = "StringEquals"
      values = [
        "sagemaker.amazonaws.com"
      ]
      variable = "iam:PassedToService"
    }
  }
}

data "aws_iam_policy_document" "dynamodb" {
  statement {
    sid = "Items"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
    ]

    effect = "Allow"

    resources = [
      module.metaflow-step-functions.metaflow_step_functions_dynamodb_table_arn
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch" {
  statement {
    sid = "AllowPutLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    effect = "Allow"

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy" "grant_custom_s3_list_batch" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "s3_list"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.custom_s3_list_batch.json
}

resource "aws_iam_role_policy" "grant_custom_s3_batch" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "custom_s3"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.custom_s3_batch.json
}

resource "aws_iam_role_policy" "grant_s3_kms" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "s3_kms"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.s3_kms.json
}

resource "aws_iam_role_policy" "grant_deny_presigned_batch" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "deny_presigned"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.deny_presigned_batch.json
}

resource "aws_iam_role_policy" "grant_allow_sagemaker" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "sagemaker"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.allow_sagemaker.json
}

resource "aws_iam_role_policy" "grant_iam_pass_role" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "iam_pass_role"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.iam_pass_role.json
}

resource "aws_iam_role_policy" "grant_dynamodb" {
  count  = var.enable_step_functions && var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "dynamodb"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.dynamodb.json
}

resource "aws_iam_role_policy" "grant_cloudwatch" {
  count  = var.existing_batch_s3_task_role_name == "" ? 1 : 0
  name   = "cloudwatch"
  role   = local.batch_s3_task_role_name_actual
  policy = data.aws_iam_policy_document.cloudwatch.json
}
