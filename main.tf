locals {
  managed_allow_list_ids = toset([
    for allow_list in volcenginecc_kafka_allow_list.this : allow_list.allow_list_id
  ])
  effective_allow_list_ids = setunion(var.allow_list_ids, local.managed_allow_list_ids)

  instance_parameters = jsonencode({
    AutoDeleteGroup        = tostring(var.instance_parameters.auto_delete_group)
    LogAutoDeletion        = tostring(var.instance_parameters.log_auto_deletion)
    LogAutoDeletionPercent = tostring(var.instance_parameters.log_auto_deletion_percent)
    LogRetentionHours      = tostring(var.instance_parameters.log_retention_hours)
    MessageMaxByte         = tostring(var.instance_parameters.message_max_byte)
    MessageTimestampType   = var.instance_parameters.message_timestamp_type
    OffsetRetentionMinutes = tostring(var.instance_parameters.offset_retention_minutes)
    TransactionDisabled    = tostring(var.instance_parameters.transaction_disabled)
  })

  # Provider v0.0.71 cannot refresh an ACL containing multiple comma-separated CIDRs.
  # Keep the public input shape while creating one provider resource per CIDR.
  expanded_acls = {
    for acl in flatten([
      for logical_key, rule in var.acls : [
        for cidr in split(",", rule.ip) : merge(rule, {
          cidr        = trimspace(cidr)
          logical_key = logical_key
        })
      ]
    ]) : jsonencode([acl.logical_key, acl.cidr]) => acl
  }
}

resource "volcenginecc_kafka_allow_list" "this" {
  for_each = var.allow_lists

  allow_list      = join(",", sort(tolist(each.value.cidrs)))
  allow_list_desc = each.value.description
  allow_list_name = each.value.name
}

resource "volcenginecc_kafka_instance" "this" {
  compute_spec = var.compute_spec
  subnet_id    = var.subnet_id
  version      = var.kafka_version
  vpc_id       = var.vpc_id
  zone_id      = join(",", var.availability_zone_ids)

  charge_info = jsondecode(var.charge_type == "PostPaid" ? jsonencode({
    charge_type = var.charge_type
    }) : jsonencode({
    auto_renew  = var.auto_renew
    charge_type = var.charge_type
    period      = var.purchase_period
    period_unit = var.purchase_period_unit
  }))
  instance_description = var.instance_description
  instance_name        = var.instance_name
  ip_white_list        = local.effective_allow_list_ids
  need_rebalance       = var.need_rebalance
  parameters           = local.instance_parameters
  partition_number     = var.partition_capacity
  project_name         = var.project_name
  storage_space        = var.storage_space_gib
  storage_type         = var.storage_type
  tags = length(var.tags) == 0 ? null : [
    for key, value in var.tags : {
      key   = key
      value = value
    }
  ]

  lifecycle {
    precondition {
      condition     = length(local.effective_allow_list_ids) > 0
      error_message = "At least one managed allow_lists entry or allow_list_ids value is required; the cloud default permits all addresses."
    }

    precondition {
      condition     = var.charge_type == "PostPaid" || (var.purchase_period != null && var.purchase_period_unit != null)
      error_message = "purchase_period and purchase_period_unit are required when charge_type is PrePaid."
    }

    precondition {
      condition     = toset(keys(var.sasl_users)) == toset(keys(nonsensitive(var.sasl_user_passwords)))
      error_message = "sasl_users and sasl_user_passwords must contain exactly the same keys."
    }
  }
}

resource "volcenginecc_kafka_user" "this" {
  for_each = var.sasl_users

  all_authority = each.value.all_authority
  description   = each.value.description
  instance_id   = volcenginecc_kafka_instance.this.instance_id
  password_type = each.value.password_type
  user_name     = each.key
  user_password = var.sasl_user_passwords[each.key]
}

resource "volcenginecc_kafka_topic" "this" {
  for_each = var.topics

  all_authority    = each.value.all_authority
  cleanup_policy   = each.value.cleanup_policy
  description      = each.value.description
  instance_id      = volcenginecc_kafka_instance.this.instance_id
  partition_number = each.value.partition_number
  replica_number   = each.value.replica_number
  topic_name       = each.key
  parameters = jsonencode({
    MessageMaxByte         = tostring(each.value.message_max_byte)
    LogRetentionHours      = tostring(each.value.log_retention_hours)
    MinInsyncReplicaNumber = tostring(each.value.min_insync_replica_number)
  })
  tags = length(each.value.tags) == 0 ? null : [
    for key, value in each.value.tags : {
      key   = key
      value = value
    }
  ]
}

resource "volcenginecc_kafka_group" "this" {
  for_each = var.consumer_groups

  description = each.value.description
  group_id    = each.key
  instance_id = volcenginecc_kafka_instance.this.instance_id
  tags = length(each.value.tags) == 0 ? null : [
    for key, value in each.value.tags : {
      key   = key
      value = value
    }
  ]
}

resource "volcenginecc_kafka_acl" "this" {
  for_each = local.expanded_acls

  access_policy = each.value.access_policy
  instance_id   = volcenginecc_kafka_instance.this.instance_id
  ip            = each.value.cidr
  pattern_type  = each.value.pattern_type
  resource      = each.value.resource
  resource_type = each.value.resource_type
  user_name     = each.value.user_name

  depends_on = [
    volcenginecc_kafka_group.this,
    volcenginecc_kafka_topic.this,
    volcenginecc_kafka_user.this,
  ]
}
