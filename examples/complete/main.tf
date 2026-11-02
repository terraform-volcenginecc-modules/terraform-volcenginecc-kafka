provider "volcenginecc" {
  region = var.region
}

resource "volcenginecc_tls_project" "log_source" {
  project_name     = "${var.instance_name}-logs"
  description      = "Temporary log source for the complete Kafka example."
  iam_project_name = var.project_name
}

resource "volcenginecc_tls_topic" "log_source" {
  project_id     = volcenginecc_tls_project.log_source.project_id
  topic_name     = "${var.instance_name}-source"
  description    = "Logs delivered to the managed Kafka log_export Topic."
  shard_count    = 1
  ttl            = 1
  auto_split     = false
  allow_consume  = false
  enable_hot_ttl = false
  log_public_ip  = false
}

resource "volcenginecc_tls_index" "log_source" {
  topic_id          = volcenginecc_tls_topic.log_source.topic_id
  enable_auto_index = true
  max_text_len      = 2048

  full_text = {
    case_sensitive = false
    delimiter = chomp(<<-EOT
    , '";$#!=()[]{}?@&<>/:\n\t\r\\%*+-._^`|~
    EOT
    )
    include_chinese = true
  }
}

module "kafka" {
  source  = "terraform-volcenginecc-modules/kafka/volcenginecc"
  version = "~> 1.0"

  instance_name         = var.instance_name
  instance_description  = "Private Kafka cluster with explicit multi-Topic ACLs."
  vpc_id                = var.vpc_id
  subnet_id             = var.subnet_id
  availability_zone_ids = var.availability_zone_ids
  compute_spec          = var.compute_spec
  storage_space_gib     = 500
  storage_type          = "ESSD_FlexPL"

  instance_parameters = {
    message_max_byte         = 10
    log_retention_hours      = 168
    offset_retention_minutes = 10080
    message_timestamp_type   = "CreateTime"
  }

  allow_lists = {
    private_clients = {
      name        = "${var.instance_name}-private-clients"
      cidrs       = var.private_client_cidrs
      description = "Private application networks permitted to access Kafka."
    }
    tls_shipper = {
      name        = "${var.instance_name}-tls-shipper"
      cidrs       = ["100.64.0.0/10"]
      description = "Managed TLS Kafka Shipper service network."
    }
  }

  sasl_users = {
    event_producer = {
      all_authority = false
      password_type = "Scram"
      description   = "Producer for event and CDC streams."
    }
    stream_consumer = {
      all_authority = false
      password_type = "Scram"
      description   = "Consumer for event and CDC streams."
    }
  }
  sasl_user_passwords = {
    event_producer  = var.producer_password
    stream_consumer = var.consumer_password
  }

  topics = {
    application_events = {
      partition_number          = 12
      replica_number            = 3
      min_insync_replica_number = 2
      log_retention_hours       = 168
      all_authority             = false
      description               = "Application domain events."
      tags = {
        DataClass = "events"
      }
    }
    database_cdc = {
      partition_number          = 12
      replica_number            = 3
      min_insync_replica_number = 2
      log_retention_hours       = 72
      cleanup_policy            = ["delete", "compact"]
      all_authority             = false
      description               = "Database change data capture stream."
      tags = {
        DataClass = "cdc"
      }
    }
    log_export = {
      partition_number          = 6
      replica_number            = 3
      min_insync_replica_number = 2
      log_retention_hours       = 24
      all_authority             = true
      description               = "Destination for TLS log delivery."
      tags = {
        DataClass = "logs"
      }
    }
  }

  consumer_groups = {
    stream_processors = {
      description = "Real-time processors consuming both managed Topics."
      tags = {
        Workload = "stream-processing"
      }
    }
  }

  acls = {
    producer_application_events = {
      user_name     = "event_producer"
      ip            = join(",", sort(tolist(var.private_client_cidrs)))
      resource_type = "Topic"
      resource      = "application_events"
      access_policy = "Write"
    }
    producer_database_cdc = {
      user_name     = "event_producer"
      ip            = join(",", sort(tolist(var.private_client_cidrs)))
      resource_type = "Topic"
      resource      = "database_cdc"
      access_policy = "Write"
    }
    consumer_application_events = {
      user_name     = "stream_consumer"
      ip            = join(",", sort(tolist(var.private_client_cidrs)))
      resource_type = "Topic"
      resource      = "application_events"
      access_policy = "Read"
    }
    consumer_database_cdc = {
      user_name     = "stream_consumer"
      ip            = join(",", sort(tolist(var.private_client_cidrs)))
      resource_type = "Topic"
      resource      = "database_cdc"
      access_policy = "Read"
    }
    consumer_group = {
      user_name     = "stream_consumer"
      ip            = join(",", sort(tolist(var.private_client_cidrs)))
      resource_type = "Group"
      resource      = "stream_processors"
      access_policy = "Read"
    }
  }

  project_name = var.project_name
  tags = {
    Environment = "example"
    Scenario    = "private-sasl-multi-topic"
  }
}

resource "volcenginecc_tls_shipper" "kafka" {
  topic_id     = volcenginecc_tls_topic.log_source.topic_id
  shipper_name = "${var.instance_name}-kafka"
  shipper_type = "kafka"
  status       = true

  content_info = {
    format = "json"
    json_info = {
      enable = true
      escape = true
      keys = [
        "__content__",
        "__source__",
        "__time__",
      ]
    }
  }

  kafka_shipper_info = {
    compress    = "gzip"
    instance    = module.kafka.instance_id
    kafka_topic = module.kafka.topic_names["log_export"]
  }

  depends_on = [volcenginecc_tls_index.log_source]
}
