resource "aws_ecr_repository" "metaflow_batch_image" {
  count = var.enable_custom_batch_container_registry ? 1 : 0

  name = local.metaflow_batch_image_name

  tags = var.tags
}

# ECR repository for metadata service (managed externally)
# Repository should be created manually:
# aws ecr create-repository --repository-name metaflow-metadata-service --region us-west-1

# Data source to reference existing ECR repository
data "aws_ecr_repository" "metaflow_metadata_service" {
  count = var.use_ecr_for_metadata_service ? 1 : 0
  name  = "metaflow-metadata-service"
}

# Note: Image should be manually pushed to ECR repository
# Manual commands:
# aws ecr get-login-password --region us-west-1 --profile development-admin | docker login --username AWS --password-stdin 934977584361.dkr.ecr.us-west-1.amazonaws.com
# docker pull netflixoss/metaflow_metadata_service:v2.3.0
# docker tag netflixoss/metaflow_metadata_service:v2.3.0 934977584361.dkr.ecr.us-west-1.amazonaws.com/metaflow-metadata-service:v2.3.0
# docker push 934977584361.dkr.ecr.us-west-1.amazonaws.com/metaflow-metadata-service:v2.3.0
