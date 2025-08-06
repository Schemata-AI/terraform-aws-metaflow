variable "active" {
  default     = false
  description = "When true step function infrastructure is provisioned."
  type        = bool
}

variable "batch_job_queue_arn" {
  type        = string
  description = "Batch job queue arn"
}

variable "iam_partition" {
  type        = string
  default     = "aws"
  description = "IAM Partition (Select aws-us-gov for AWS GovCloud, otherwise leave as is)"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix given to all AWS resources to differentiate between applications"
}

variable "resource_suffix" {
  type        = string
  description = "Suffix given to all AWS resources to differentiate between environment and workspace"
}

variable "s3_bucket_arn" {
  type        = string
  description = "arn of the metaflow datastore s3 bucket"
}

variable "s3_bucket_kms_arn" {
  type        = string
  description = "arn of the metaflow datastore s3 bucket's kms key"
}

variable "standard_tags" {
  type        = map(string)
  description = "The standard tags to apply to every AWS resource."
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

variable "shared_iam_account_id" {
  type        = string
  description = "AWS account ID where IAM roles are hosted (separate from deployment account)"
  default     = ""
}
