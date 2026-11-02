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

output "consumer_group_ids" {
  description = "Kafka Consumer Groups created by the example."
  value       = module.kafka.consumer_group_ids
}
