resource "aws_ecr_repository" "metaflow_batch_image" {
  count = var.enable_custom_batch_container_registry ? 1 : 0

  name = local.metaflow_batch_image_name

  tags = var.tags
}

# ECR repository for metadata service
resource "aws_ecr_repository" "metaflow_metadata_service" {
  name                 = "metaflow-metadata-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = var.tags
}
