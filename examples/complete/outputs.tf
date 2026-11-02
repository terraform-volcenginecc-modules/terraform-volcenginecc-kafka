output "instance_id" {
  description = "ID of the Kafka instance."
  value       = module.kafka.instance_id
}

output "connection_info" {
  description = "Kafka connection endpoints returned by the cloud."
  value       = module.kafka.connection_info
}

output "topic_names" {
  description = "Kafka Topics created by the example."
  value       = module.kafka.topic_names
}

output "sasl_user_names" {
  description = "SASL users created by the example."
  value       = module.kafka.sasl_user_names
}

output "consumer_group_ids" {
  description = "Kafka Consumer Groups created by the example."
  value       = module.kafka.consumer_group_ids
}

output "acl_ids" {
  description = "Kafka ACL rules created by the example."
  value       = module.kafka.acl_ids
}

output "log_export" {
  description = "TLS-to-Kafka log delivery resources created by the example."
  value = {
    tls_project_id       = volcenginecc_tls_project.log_source.project_id
    tls_topic_id         = volcenginecc_tls_topic.log_source.topic_id
    tls_index_id         = volcenginecc_tls_index.log_source.id
    tls_index_auto_field = volcenginecc_tls_index.log_source.enable_auto_index
    tls_index_full_text  = volcenginecc_tls_index.log_source.full_text
    shipper_id           = volcenginecc_tls_shipper.kafka.shipper_id
    shipper_status       = volcenginecc_tls_shipper.kafka.status
    kafka_topic          = module.kafka.topic_names["log_export"]
  }
}
