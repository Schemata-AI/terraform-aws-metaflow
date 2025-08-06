data "aws_iam_policy_document" "metadata_svc_ecs_task_assume_role" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

# Create wrapper role that assumes the shared metadata ECS task role
resource "aws_iam_role" "metadata_svc_ecs_task_wrapper_role" {
  name = "${var.resource_prefix}metadata-ecs-task-wrapper${var.resource_suffix}"
  description = "Wrapper role that assumes the shared metadata ECS task role"
  assume_role_policy = data.aws_iam_policy_document.metadata_svc_ecs_task_assume_role.json

  tags = var.standard_tags
}

resource "aws_iam_role_policy" "assume_shared_metadata_role" {
  name = "assume-shared-metadata-role"
  role = aws_iam_role.metadata_svc_ecs_task_wrapper_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:${var.iam_partition}:iam::${var.shared_iam_account_id}:role/${var.existing_metadata_ecs_task_role_name}"
      }
    ]
  })
}

# Keep the original role creation for backwards compatibility when no existing role is specified
resource "aws_iam_role" "metadata_svc_ecs_task_role" {
  count = var.existing_metadata_ecs_task_role_name == "" ? 1 : 0
  name = "${var.resource_prefix}metadata-ecs-task${var.resource_suffix}"
  description = "This role is passed to AWS ECS' task definition as the `task_role`. This allows the running of the Metaflow Metadata Service to have the proper permissions to speak to other AWS resources."
  assume_role_policy = data.aws_iam_policy_document.metadata_svc_ecs_task_assume_role.json

  tags = var.standard_tags
}

# Note: We construct the ARN directly instead of using data source for existing roles
# because the role exists in a different AWS account (shared_iam_account_id)

data "aws_iam_policy_document" "s3_kms" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = [
      var.datastore_s3_bucket_kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "custom_s3_batch" {
  statement {
    sid = "ObjectAccessMetadataService"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "${var.s3_bucket_arn}/*",
      "${var.s3_bucket_arn}"
    ]
  }
}

data "aws_iam_policy_document" "deny_presigned_batch" {
  statement {
    sid = "DenyPresignedBatch"

    effect = "Deny"

    actions = [
      "s3:*"
    ]

    resources = [
      "*"
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

resource "aws_iam_role_policy" "grant_s3_kms" {
  count  = var.existing_metadata_ecs_task_role_name == "" ? 1 : 0
  name   = "s3_kms"
  role   = local.metadata_ecs_task_role_name_actual
  policy = data.aws_iam_policy_document.s3_kms.json
}

resource "aws_iam_role_policy" "grant_custom_s3_batch" {
  count  = var.existing_metadata_ecs_task_role_name == "" ? 1 : 0
  name   = "custom_s3"
  role   = local.metadata_ecs_task_role_name_actual
  policy = data.aws_iam_policy_document.custom_s3_batch.json
}

resource "aws_iam_role_policy" "grant_deny_presigned_batch" {
  count  = var.existing_metadata_ecs_task_role_name == "" ? 1 : 0
  name   = "deny_presigned"
  role   = local.metadata_ecs_task_role_name_actual
  policy = data.aws_iam_policy_document.deny_presigned_batch.json
}
