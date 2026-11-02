variable "instance_name" {
  type        = string
  description = "Name of the Kafka instance."
  nullable    = false

  validation {
    condition     = length(var.instance_name) >= 1 && length(var.instance_name) <= 128 && can(regex("^[^0-9-][A-Za-z0-9_-]*$", var.instance_name))
    error_message = "instance_name must be 1-128 characters, must not start with a digit or hyphen, and may contain letters, digits, underscores, or hyphens."
  }
}

variable "instance_description" {
  type        = string
  description = "Optional description of the Kafka instance."
  default     = null

  validation {
    condition     = var.instance_description == null ? true : length(var.instance_description) >= 1 && length(var.instance_description) <= 128
    error_message = "instance_description must be null or contain 1-128 characters."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC for private Kafka access."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  description = "ID of the existing subnet for the Kafka instance."
  nullable    = false
}

variable "availability_zone_ids" {
  type        = list(string)
  description = "Availability zone IDs for the Kafka instance. Multiple entries request cross-AZ deployment."
  nullable    = false

  validation {
    condition     = length(var.availability_zone_ids) > 0 && alltrue([for zone_id in var.availability_zone_ids : trimspace(zone_id) != ""])
    error_message = "availability_zone_ids must contain at least one non-empty zone ID."
  }
}

variable "compute_spec" {
  type        = string
  description = "Kafka compute specification sold in the target region. The Provider does not expose broker count separately."
  nullable    = false

  validation {
    condition     = trimspace(var.compute_spec) != ""
    error_message = "compute_spec must not be empty."
  }
}

variable "kafka_version" {
  type        = string
  description = "Kafka engine version."
  default     = "2.8.2"
  nullable    = false

  validation {
    condition     = contains(["2.2.2", "2.8.2"], var.kafka_version)
    error_message = "kafka_version must be 2.2.2 or 2.8.2."
  }
}

variable "storage_space_gib" {
  type        = number
  description = "Kafka storage capacity in GiB, as a positive multiple of 100."
  nullable    = false

  validation {
    condition     = var.storage_space_gib > 0 && var.storage_space_gib % 100 == 0
    error_message = "storage_space_gib must be a positive multiple of 100."
  }
}

variable "storage_type" {
  type        = string
  description = "Cloud disk type for Kafka data."
  default     = "ESSD_FlexPL"
  nullable    = false

  validation {
    condition     = contains(["ESSD_FlexPL", "ESSD_PL0"], var.storage_type)
    error_message = "storage_type must be ESSD_FlexPL or ESSD_PL0."
  }
}

variable "partition_capacity" {
  type        = number
  description = "Optional purchased partition capacity. This Provider field is write-only."
  default     = null

  validation {
    condition     = var.partition_capacity == null ? true : var.partition_capacity > 0 && floor(var.partition_capacity) == var.partition_capacity
    error_message = "partition_capacity must be null or a positive integer."
  }
}

variable "need_rebalance" {
  type        = bool
  description = "Optional write-only rebalance request used with a supported capacity change."
  default     = null
}

variable "instance_parameters" {
  type = object({
    auto_delete_group         = optional(bool, false)
    log_auto_deletion         = optional(bool, true)
    log_auto_deletion_percent = optional(number, 90)
    log_retention_hours       = optional(number, 72)
    message_max_byte          = optional(number, 10)
    message_timestamp_type    = optional(string, "CreateTime")
    offset_retention_minutes  = optional(number, 4320)
    transaction_disabled      = optional(bool, false)
  })
  description = "Initial Kafka instance parameters encoded as JSON for the Provider."
  default     = {}
  nullable    = false

  validation {
    condition = (
      var.instance_parameters.message_max_byte >= 1 &&
      var.instance_parameters.message_max_byte <= 12 &&
      var.instance_parameters.log_auto_deletion_percent >= 1 &&
      var.instance_parameters.log_auto_deletion_percent <= 100 &&
      var.instance_parameters.log_retention_hours >= 0 &&
      var.instance_parameters.log_retention_hours <= 2160 &&
      var.instance_parameters.offset_retention_minutes >= 1 &&
      var.instance_parameters.offset_retention_minutes <= 10080 &&
      contains(["CreateTime", "LogAppendTime"], var.instance_parameters.message_timestamp_type)
    )
    error_message = "instance_parameters values are outside the Provider-documented Kafka ranges."
  }
}

variable "allow_list_ids" {
  type        = set(string)
  description = "IDs of existing Kafka allowlists to bind during instance creation."
  default     = []
  nullable    = false
}

variable "allow_lists" {
  type = map(object({
    name        = string
    cidrs       = set(string)
    description = optional(string)
  }))
  description = "Kafka allowlists managed by this module. Map keys provide stable Terraform addresses."
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for allow_list in values(var.allow_lists) :
      length(allow_list.cidrs) > 0 &&
      alltrue([
        for cidr in allow_list.cidrs :
        cidr != "0.0.0.0/0" && cidr != "::/0" && can(cidrnetmask(cidr))
      ])
    ])
    error_message = "Each managed allowlist must contain valid IPv4 CIDRs and must not include 0.0.0.0/0 or ::/0."
  }
}

variable "sasl_users" {
  type = map(object({
    all_authority = optional(bool, false)
    description   = optional(string)
    password_type = optional(string, "Scram")
  }))
  description = "SASL users managed by this module, keyed by the actual Kafka username."
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for user_name, user in var.sasl_users :
      length(user_name) >= 3 &&
      length(user_name) <= 64 &&
      can(regex("^[A-Za-z0-9_-]+$", user_name)) &&
      !contains(["admin", "monitor"], lower(user_name)) &&
      contains(["Scram", "Plain"], user.password_type)
    ])
    error_message = "SASL user keys must be valid non-reserved usernames and password_type must be Scram or Plain."
  }
}

variable "sasl_user_passwords" {
  type        = map(string)
  description = "Passwords for sasl_users, keyed identically. Values enter Terraform State because the Provider does not mark user_password sensitive."
  default     = {}
  nullable    = false
  sensitive   = true

  validation {
    condition = alltrue([
      for password in values(var.sasl_user_passwords) :
      length(password) >= 8 &&
      length(password) <= 32 &&
      (
        (length(regexall("[A-Z]", password)) > 0 ? 1 : 0) +
        (length(regexall("[a-z]", password)) > 0 ? 1 : 0) +
        (length(regexall("[0-9]", password)) > 0 ? 1 : 0) +
        (length(regexall("[!@#$%^&*()_+\\-=]", password)) > 0 ? 1 : 0)
      ) >= 3
    ])
    error_message = "Each SASL password must be 8-32 characters and include at least three supported character categories."
  }
}

variable "topics" {
  type = map(object({
    partition_number          = number
    replica_number            = optional(number, 3)
    min_insync_replica_number = optional(number, 2)
    message_max_byte          = optional(number, 10)
    log_retention_hours       = optional(number, 72)
    cleanup_policy            = optional(set(string), ["delete"])
    all_authority             = optional(bool, false)
    description               = optional(string)
    tags                      = optional(map(string), {})
  }))
  description = "Kafka Topics managed by this module, keyed by the actual Topic name."
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for topic_name, topic in var.topics :
      length(topic_name) >= 3 &&
      length(topic_name) <= 64 &&
      can(regex("^[A-Za-z0-9][A-Za-z0-9._-]*$", topic_name)) &&
      topic.partition_number >= 1 &&
      topic.partition_number <= 300 &&
      floor(topic.partition_number) == topic.partition_number &&
      contains([2, 3], topic.replica_number) &&
      topic.min_insync_replica_number >= 1 &&
      topic.min_insync_replica_number <= topic.replica_number &&
      topic.message_max_byte >= 1 &&
      topic.message_max_byte <= 12 &&
      topic.log_retention_hours >= 1 &&
      topic.log_retention_hours <= 2160 &&
      length(topic.cleanup_policy) >= 1 &&
      alltrue([for policy in topic.cleanup_policy : contains(["delete", "compact"], policy)])
    ])
    error_message = "One or more Topic names, partition/replica settings, retention settings, or cleanup policies are invalid."
  }
}

variable "consumer_groups" {
  type = map(object({
    description = optional(string)
    tags        = optional(map(string), {})
  }))
  description = "Kafka Consumer Groups managed by this module, keyed by the actual Group ID."
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for group_id in keys(var.consumer_groups) :
      length(group_id) >= 3 &&
      length(group_id) <= 128 &&
      can(regex("^[A-Za-z0-9@_-]+$", group_id)) &&
      can(regex("[A-Za-z0-9]", group_id))
    ])
    error_message = "Consumer Group keys must be valid Kafka Group IDs containing at least one letter or digit."
  }
}

variable "acls" {
  type = map(object({
    user_name     = string
    ip            = string
    resource_type = string
    pattern_type  = optional(string, "Literal")
    resource      = string
    access_policy = string
  }))
  description = "Kafka ACL rules managed by this module. Every map key is a stable, create-only rule identity."
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for acl in values(var.acls) :
      contains(["Topic", "Group"], acl.resource_type) &&
      contains(["Literal", "Prefixed"], acl.pattern_type) &&
      contains(["Read", "Write"], acl.access_policy) &&
      trimspace(acl.user_name) != "" &&
      trimspace(acl.resource) != "" &&
      alltrue([
        for cidr in split(",", acl.ip) :
        trimspace(cidr) != "*" &&
        trimspace(cidr) != "0.0.0.0/0" &&
        trimspace(cidr) != "::/0" &&
        can(cidrnetmask(trimspace(cidr)))
      ])
    ])
    error_message = "ACLs require supported resource/pattern/access values and explicit non-public CIDRs; wildcard and world-open IP rules are rejected."
  }
}

variable "charge_type" {
  type        = string
  description = "Kafka billing type."
  default     = "PostPaid"
  nullable    = false

  validation {
    condition     = contains(["PostPaid", "PrePaid"], var.charge_type)
    error_message = "charge_type must be PostPaid or PrePaid."
  }
}

variable "purchase_period" {
  type        = number
  description = "Purchase duration for a prepaid instance."
  default     = null

  validation {
    condition     = var.purchase_period == null ? true : var.purchase_period > 0 && floor(var.purchase_period) == var.purchase_period
    error_message = "purchase_period must be null or a positive integer."
  }
}

variable "purchase_period_unit" {
  type        = string
  description = "Purchase period unit for a prepaid instance."
  default     = null

  validation {
    condition     = var.purchase_period_unit == null ? true : contains(["Month", "Monthly", "Year", "Yearly"], var.purchase_period_unit)
    error_message = "purchase_period_unit must be Month, Monthly, Year, Yearly, or null."
  }
}

variable "auto_renew" {
  type        = bool
  description = "Whether a prepaid instance renews automatically."
  default     = false
  nullable    = false
}

variable "project_name" {
  type        = string
  description = "Optional Volcengine IAM project name."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Kafka instance."
  default     = {}
  nullable    = false
}
