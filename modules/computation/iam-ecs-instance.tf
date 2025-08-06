data "aws_iam_policy_document" "ecs_instance_role_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      identifiers = [
        "ec2.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_instance_wrapper_role" {
  name               = "${var.resource_prefix}ecs-instance-wrapper-role${var.resource_suffix}"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_role_assume_role.json
  description        = "Wrapper role that assumes the shared ECS instance role"
  
  tags = var.standard_tags
}

resource "aws_iam_role_policy" "assume_shared_ecs_instance_role" {
  name = "assume-shared-role"
  role = aws_iam_role.ecs_instance_wrapper_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:${var.iam_partition}:iam::${var.shared_iam_account_id}:role/${var.existing_ecs_instance_role_name}"
      }
    ]
  })
}
