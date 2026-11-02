variable "region" {
  type        = string
  description = "Volcengine region in which to create Kafka resources."
}

variable "instance_name" {
  type        = string
  description = "Name of the Kafka instance."
  default     = "kafka-basic-example"
}

variable "vpc_id" {
  type        = string
  description = "ID of an existing VPC."
}

variable "subnet_id" {
  type        = string
  description = "ID of an existing subnet."
}

variable "availability_zone_id" {
  type        = string
  description = "Availability zone ID for the Kafka instance."
}

variable "compute_spec" {
  type        = string
  description = "Kafka compute specification available in the target region."
}

variable "application_cidr" {
  type        = string
  description = "Private application CIDR permitted to connect to Kafka."

  validation {
    condition     = var.application_cidr != "0.0.0.0/0" && can(cidrnetmask(var.application_cidr))
    error_message = "application_cidr must be a valid, non-public IPv4 CIDR."
  }
}

variable "sasl_password" {
  type        = string
  description = "Password for the basic_app SASL user."
  sensitive   = true
}
