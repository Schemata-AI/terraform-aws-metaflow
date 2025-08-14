variable "access_list_cidr_blocks" {
  type        = list(string)
  description = "List of CIDRs we want to grant access to our Metaflow Metadata Service. Usually this is our VPN's CIDR blocks."
  default     = []
}

variable "batch_type" {
  type        = string
  description = "AWS Batch Compute Type ('ec2', 'fargate')"
  default     = "ec2"
}

variable "db_migrate_lambda_zip_file" {
  type        = string
  description = "Output path for the zip file containing the DB migrate lambda"
  default     = null
}

variable "enable_custom_batch_container_registry" {
  type        = bool
  default     = false
  description = "Provisions infrastructure for custom Amazon ECR container registry if enabled"
}

variable "use_ecr_for_metadata_service" {
  type        = bool
  default     = true
  description = "Use ECR instead of Docker Hub for metadata service container image. This avoids internet connectivity issues."
}

variable "aws_profile" {
  type        = string
  default     = ""
  description = "AWS profile to use for ECR operations. If empty, uses default profile."
}

variable "database_ssl_mode" {
  type        = string
  description = "The metadata service database connection ssl mode"
  default     = ""  # Empty means use default logic
  
  validation {
    condition     = var.database_ssl_mode == "" || contains(["disable", "allow", "prefer", "require", "verify-ca", "verify-full"], var.database_ssl_mode)
    error_message = "The database_ssl_mode variable must be empty or one of: disable, allow, prefer, require, verify-ca, verify-full."
  }
}

variable "enable_step_functions" {
  type        = bool
  description = "Provisions infrastructure for step functions if enabled"
}

variable "resource_prefix" {
  default     = "metaflow"
  description = "string prefix for all resources"
}

variable "resource_suffix" {
  default     = ""
  description = "string suffix for all resources"
}

variable "compute_environment_desired_vcpus" {
  type        = number
  description = "Desired Starting VCPUs for Batch Compute Environment [0-16] for EC2 Batch Compute Environment (ignored for Fargate)"
  default     = 8
}

variable "compute_environment_instance_types" {
  type        = list(string)
  description = "The instance types for the compute environment"
  default     = ["c4.large", "c4.xlarge", "c4.2xlarge", "c4.4xlarge", "c4.8xlarge"]
}

variable "compute_environment_min_vcpus" {
  type        = number
  description = "Minimum VCPUs for Batch Compute Environment [0-16] for EC2 Batch Compute Environment (ignored for Fargate)"
  default     = 8
}

variable "compute_environment_max_vcpus" {
  type        = number
  description = "Maximum VCPUs for Batch Compute Environment [16-96]"
  default     = 64
}

variable "compute_environment_egress_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks to which egress is allowed from the Batch Compute environment's security group"
}

variable "db_instance_type" {
  type        = string
  description = "RDS instance type to launch for PostgresQL database."
  default     = "db.t2.small"
}

variable "db_engine_version" {
  type    = string
  default = "11"
}

variable "launch_template_http_endpoint" {
  type        = string
  description = "Whether the metadata service is available. Can be 'enabled' or 'disabled'"
  default     = "enabled"
}

variable "launch_template_http_tokens" {
  type        = string
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Can be 'optional' or 'required'"
  default     = "optional"
}

variable "launch_template_http_put_response_hop_limit" {
  type        = number
  description = "The desired HTTP PUT response hop limit for instance metadata requests. Can be an integer from 1 to 64"
  default     = 2
}

variable "iam_partition" {
  type        = string
  default     = "aws"
  description = "IAM Partition (Select aws-us-gov for AWS GovCloud, otherwise leave as is)"
}

variable "metadata_service_container_image" {
  type        = string
  default     = ""
  description = "Container image for metadata service"
}

variable "metadata_service_enable_api_basic_auth" {
  type        = bool
  default     = true
  description = "Enable basic auth for API Gateway? (requires key export)"
}

variable "metadata_service_enable_api_gateway" {
  type        = bool
  default     = true
  description = "Enable API Gateway for public metadata service endpoint"
}

variable "ui_static_container_image" {
  type        = string
  default     = ""
  description = "Container image for the UI frontend app"
}

variable "tags" {
  description = "aws tags"
  type        = map(string)
}

variable "ui_alb_internal" {
  type        = bool
  description = "Defines whether the ALB for the UI is internal"
  default     = false
}

# variables from infra project that defines the VPC we will deploy to

variable "subnet1_id" {
  type        = string
  description = "First subnet used for availability zone redundancy"
}

variable "subnet2_id" {
  type        = string
  description = "Second subnet used for availability zone redundancy"
}

variable "vpc_cidr_blocks" {
  type        = list(string)
  description = "The VPC CIDR blocks that we'll access list on our Metadata Service API to allow all internal communications"
}

variable "vpc_id" {
  type        = string
  description = "The id of the single VPC we stood up for all Metaflow resources to exist in."
}

variable "ui_certificate_arn" {
  type        = string
  default     = ""
  description = "SSL certificate for UI. If set to empty string, UI is disabled. "
}

variable "ui_allow_list" {
  type        = list(string)
  default     = []
  description = "List of CIDRs we want to grant access to our Metaflow UI Service. Usually this is our VPN's CIDR blocks."
}

variable "extra_ui_backend_env_vars" {
  type        = map(string)
  default     = {}
  description = "Additional environment variables for UI backend container"
}

variable "extra_ui_static_env_vars" {
  type        = map(string)
  default     = {}
  description = "Additional environment variables for UI static app"
}

variable "with_public_ip" {
  type        = bool
  description = "Enable public IP assignment for the Metadata Service. If the subnets specified for subnet1_id and subnet2_id are public subnets, you will NEED to set this to true to allow pulling container images from public registries. Otherwise this should be set to false."
}

variable "force_destroy_s3_bucket" {
  type        = bool
  description = "Empty S3 bucket before destroying via terraform destroy"
  default     = false
}

variable "enable_key_rotation" {
  type        = bool
  description = "Enable key rotation for KMS keys"
  default     = false
}

variable "existing_batch_s3_task_role_name" {
  type        = string
  description = "Name of existing IAM role for Batch S3 tasks. If provided, role will not be created."
  default     = ""
}

variable "existing_ecs_execution_role_name" {
  type        = string
  description = "Name of existing ECS execution role. If provided, role will not be created."
  default     = ""
}

variable "shared_iam_account_id" {
  type        = string
  description = "AWS account ID where IAM roles are hosted (separate from deployment account)"
  default     = ""
}

variable "existing_batch_execution_role_name" {
  type        = string
  description = "Name of existing Batch execution role. If provided, role will not be created."
  default     = ""
}

variable "existing_ecs_instance_role_name" {
  type        = string
  description = "Name of existing ECS instance role. If provided, role will not be created."
  default     = ""
}

variable "existing_ecs_instance_profile_name" {
  type        = string
  description = "Name of existing ECS instance profile. If provided, instance profile will not be created."
  default     = ""
}

variable "existing_metadata_ecs_task_role_name" {
  type        = string
  description = "Name of existing metadata service ECS task role. If provided, role will not be created."
  default     = ""
}

variable "existing_lambda_execution_role_name" {
  type        = string
  description = "Name of existing Lambda execution role. If provided, role will not be created."
  default     = ""
}

variable "existing_eventbridge_role_name" {
  type        = string
  description = "Name of existing EventBridge role. If provided, role will not be created."
  default     = ""
}

variable "existing_step_functions_role_name" {
  type        = string
  description = "Name of existing Step Functions role. If provided, role will not be created."
  default     = ""
}

variable "metadata_service_cpu" {
  type        = number
  default     = 512
  description = "ECS task CPU units for metadata service (Fargate: 256, 512, 1024, 2048, 4096)"
}

variable "metadata_service_memory" {
  type        = number
  default     = 1024
  description = "ECS task memory in MiB for metadata service"
}

variable "enable_fck_nat" {
  type        = bool
  default     = false
  description = "Enable fck-nat instances for cost-optimized outbound internet access instead of NAT Gateway"
}

variable "fck_nat_instance_type" {
  type        = string
  default     = "t3.nano"
  description = "Instance type for fck-nat instances (t3.nano recommended for cost optimization)"
}
