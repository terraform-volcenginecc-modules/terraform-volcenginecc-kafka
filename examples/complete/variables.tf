variable "region" {
  type        = string
  description = "Volcengine region in which to create Kafka resources."
}

variable "instance_name" {
  type        = string
  description = "Name of the Kafka instance."
  default     = "kafka-complete-example"
}

variable "vpc_id" {
  type        = string
  description = "ID of an existing VPC."
}

variable "subnet_id" {
  type        = string
  description = "ID of an existing subnet."
}

variable "availability_zone_ids" {
  type        = list(string)
  description = "Availability zone IDs used for cross-AZ Kafka deployment."

  validation {
    condition     = length(var.availability_zone_ids) == 3 && length(distinct(var.availability_zone_ids)) == 3
    error_message = "availability_zone_ids must contain exactly three distinct zones for a Kafka multi-AZ deployment."
  }
}

variable "compute_spec" {
  type        = string
  description = "Kafka compute specification available in the target region."
}

variable "private_client_cidrs" {
  type        = set(string)
  description = "Private client CIDRs allowed by the Kafka allowlist and ACL rules."

  validation {
    condition = (
      length(var.private_client_cidrs) > 0 &&
      alltrue([
        for cidr in var.private_client_cidrs :
        cidr != "0.0.0.0/0" && can(cidrnetmask(cidr))
      ])
    )
    error_message = "private_client_cidrs must contain valid, non-public IPv4 CIDRs."
  }
}

variable "producer_password" {
  type        = string
  description = "Password for the event_producer SASL user."
  sensitive   = true
}

variable "consumer_password" {
  type        = string
  description = "Password for the stream_consumer SASL user."
  sensitive   = true
}

variable "project_name" {
  type        = string
  description = "Optional Volcengine IAM project name."
  default     = null
}
