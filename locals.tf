module "metaflow-common" {
  source = "./modules/common"
}

locals {
  resource_prefix = length(var.resource_prefix) > 0 ? "${var.resource_prefix}-" : ""
  resource_suffix = length(var.resource_suffix) > 0 ? "-${var.resource_suffix}" : ""

  aws_region     = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id

  batch_s3_task_role_name   = "${local.resource_prefix}batch_s3_task_role${local.resource_suffix}"
  metaflow_batch_image_name = "${local.resource_prefix}batch${local.resource_suffix}"
  metadata_service_container_image = (
    var.metadata_service_container_image == "" ?
    (var.use_ecr_for_metadata_service ? 
      "${data.aws_ecr_repository.metaflow_metadata_service[0].repository_url}:v2.3.0" :
      module.metaflow-common.default_metadata_service_container_image) :
    var.metadata_service_container_image
  )
  ui_static_container_image = (
    var.ui_static_container_image == "" ?
    module.metaflow-common.default_ui_static_container_image :
    var.ui_static_container_image
  )

  # RDS PostgreSQL >= 15 requires SSL by default
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Concepts.General.SSL.html#PostgreSQL.Concepts.General.SSL.Requiring
  # Use user-provided SSL mode if specified, otherwise use default logic
  database_ssl_mode = var.database_ssl_mode != "" ? var.database_ssl_mode : (tonumber(split(".", var.db_engine_version)[0]) >= 15 ? "require" : "disable")
  
  # Reference to the batch S3 task role (either existing or created)
  batch_s3_task_role_name_actual = var.existing_batch_s3_task_role_name != "" ? var.existing_batch_s3_task_role_name : aws_iam_role.batch_s3_task_role[0].name
  batch_s3_task_role_arn_actual = var.existing_batch_s3_task_role_name != "" ? "arn:${var.iam_partition}:iam::${var.shared_iam_account_id}:role/${var.existing_batch_s3_task_role_name}" : aws_iam_role.batch_s3_task_role[0].arn
}
