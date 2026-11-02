provider "volcenginecc" {
  region = var.region
}

module "kafka" {
  source  = "terraform-volcenginecc-modules/kafka/volcenginecc"
  version = "~> 1.0"

  instance_name         = var.instance_name
  vpc_id                = var.vpc_id
  subnet_id             = var.subnet_id
  availability_zone_ids = [var.availability_zone_id]
  compute_spec          = var.compute_spec
  storage_space_gib     = 300

  allow_lists = {
    application = {
      name  = "${var.instance_name}-application"
      cidrs = [var.application_cidr]
    }
  }

  sasl_users = {
    basic_app = {
      all_authority = true
      password_type = "Scram"
      description   = "Basic example application user."
    }
  }
  sasl_user_passwords = {
    basic_app = var.sasl_password
  }

  topics = {
    application_events = {
      partition_number          = 6
      replica_number            = 3
      min_insync_replica_number = 2
      all_authority             = true
      description               = "Application events for asynchronous processing."
    }
  }

  consumer_groups = {
    basic_workers = {
      description = "Workers consuming the basic application event stream."
    }
  }

  tags = {
    Environment = "example"
    Scenario    = "basic-event-bus"
  }
}
