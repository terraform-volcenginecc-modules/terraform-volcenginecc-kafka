output "instance_id" {
  description = "ID of the Kafka instance."
  value       = volcenginecc_kafka_instance.this.instance_id
}

output "instance_status" {
  description = "Current Kafka instance status returned by the cloud."
  value       = volcenginecc_kafka_instance.this.instance_status
}

output "connection_info" {
  description = "Private and public endpoint metadata returned by the cloud. This module does not create public access."
  value = [
    for connection in volcenginecc_kafka_instance.this.connection_info : {
      endpoint_type     = connection.endpoint_type
      internal_endpoint = connection.internal_endpoint
      network_type      = connection.network_type
      public_endpoint   = connection.public_endpoint
    }
  ]
}

output "allow_list_ids" {
  description = "Effective Kafka allowlist IDs bound during instance creation."
  value       = local.effective_allow_list_ids
}

output "managed_allow_list_ids" {
  description = "IDs of allowlists managed by this module, keyed by input map key."
  value = {
    for key, allow_list in volcenginecc_kafka_allow_list.this : key => allow_list.allow_list_id
  }
}

output "topic_names" {
  description = "Topic names managed by this module, keyed by input map key."
  value = {
    for key, topic in volcenginecc_kafka_topic.this : key => topic.topic_name
  }
}

output "sasl_user_names" {
  description = "SASL usernames managed by this module. Passwords are never output."
  value = {
    for key, user in volcenginecc_kafka_user.this : key => user.user_name
  }
}

output "consumer_group_ids" {
  description = "Consumer Group IDs managed by this module, keyed by input map key."
  value = {
    for key, group in volcenginecc_kafka_group.this : key => group.group_id
  }
}

output "acl_ids" {
  description = "Provider IDs of ACL rules managed by this module, keyed by logical input key and then CIDR."
  value = {
    for logical_key, rule in var.acls : logical_key => {
      for cidr in split(",", rule.ip) :
      trimspace(cidr) => volcenginecc_kafka_acl.this[jsonencode([logical_key, trimspace(cidr)])].id
    }
  }
}
