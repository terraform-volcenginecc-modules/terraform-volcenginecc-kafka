# VolcengineCC Kafka Module

## 1. Overview

This Terraform module creates a private Volcengine managed Kafka cluster for event buses, log pipelines, change data capture (CDC), asynchronous decoupling, and real-time streams. It manages the Kafka instance, allowlists, Topics, SASL users, Consumer Groups, and ACL rules.

The caller owns the VPC, subnet, and client security groups. The current Provider accepts VPC and subnet IDs but exposes no Kafka security-group association field. Client security-group rules therefore remain outside this module.

## 2. Usage

```hcl
module "kafka" {
  source  = "terraform-volcenginecc-modules/kafka/volcenginecc"
  version = "~> 1.0"

  instance_name         = "events"
  vpc_id                = "vpc-..."
  subnet_id             = "subnet-..."
  availability_zone_ids = ["cn-beijing-a", "cn-beijing-b", "cn-beijing-c"]
  compute_spec          = "kafka.20xrate.hw"
  storage_space_gib     = 300

  allow_lists = {
    applications = {
      name  = "events-applications"
      cidrs = ["10.0.0.0/16"]
    }
  }

  sasl_users = {
    event_app = {
      all_authority = false
    }
  }
  sasl_user_passwords = {
    event_app = var.kafka_password
  }

  topics = {
    application_events = {
      partition_number = 6
      replica_number   = 3
    }
  }
}
```

Provider authentication and region configuration are supplied by the calling root module.

## 3. Examples

The `basic` scenario represents a basic private cluster with one Topic, one SASL user, and one Consumer Group for an event bus or asynchronous worker pipeline.

The `complete` scenario represents a three-AZ deployment with SASL authentication, private access, event and CDC streams, and TLS log delivery to a dedicated Kafka Topic. It applies separate producer, consumer, and Consumer Group ACL rules.

No separate scenario directories are introduced for log pipelines, CDC, or ACLs because these tasks are covered by the two required examples.

## 4. Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| VolcengineCC Provider | `>= 0.0.70` |

Provider `0.0.70` is the minimum because it contains all six Kafka resources used here, including Kafka ACL.

## 5. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 6. Resources

| Resource | Purpose |
|---|---|
| `volcenginecc_kafka_instance.this` | Managed Kafka cluster and private endpoint |
| `volcenginecc_kafka_allow_list.this` | Private client network allowlists |
| `volcenginecc_kafka_topic.this` | Topics, partitions, replicas, and retention |
| `volcenginecc_kafka_user.this` | SASL/PLAIN or SASL/SCRAM users |
| `volcenginecc_kafka_group.this` | Consumer Groups |
| `volcenginecc_kafka_acl.this` | Topic and Group ACL rules |

## 7. Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `instance_name` | `string` | n/a | Kafka instance name |
| `instance_description` | `string` | `null` | Kafka instance description |
| `vpc_id` | `string` | n/a | Existing VPC ID |
| `subnet_id` | `string` | n/a | Existing subnet ID |
| `availability_zone_ids` | `list(string)` | n/a | One or more availability zones |
| `compute_spec` | `string` | n/a | Region-specific Kafka compute specification |
| `kafka_version` | `string` | `"2.8.2"` | Kafka engine version |
| `storage_space_gib` | `number` | n/a | Storage in GiB, in multiples of 100 |
| `storage_type` | `string` | `"ESSD_FlexPL"` | Kafka disk type |
| `partition_capacity` | `number` | `null` | Optional write-only purchased partition capacity |
| `need_rebalance` | `bool` | `null` | Optional write-only rebalance request |
| `instance_parameters` | `object` | documented defaults | Message size, retention, offset retention, and timestamp settings |
| `allow_list_ids` | `set(string)` | `[]` | Existing allowlist IDs |
| `allow_lists` | `map(object)` | `{}` | Managed allowlists keyed by stable logical identity |
| `sasl_users` | `map(object)` | `{}` | Managed users keyed by actual username |
| `sasl_user_passwords` | `map(string)` | `{}` | Sensitive password map with the same keys as `sasl_users` |
| `topics` | `map(object)` | `{}` | Managed Topics keyed by actual Topic name |
| `consumer_groups` | `map(object)` | `{}` | Managed Consumer Groups keyed by actual Group ID |
| `acls` | `map(object)` | `{}` | Managed create-only ACL rules keyed by stable logical identity |
| `charge_type` | `string` | `"PostPaid"` | `PostPaid` or `PrePaid` billing |
| `purchase_period` | `number` | `null` | Prepaid purchase duration |
| `purchase_period_unit` | `string` | `null` | Prepaid duration unit |
| `auto_renew` | `bool` | `false` | Prepaid automatic renewal |
| `project_name` | `string` | `null` | Volcengine IAM project |
| `tags` | `map(string)` | `{}` | Kafka instance tags |

At least one managed or external allowlist is required. World-open allowlists and ACL IP rules are rejected.

## 8. Outputs

| Name | Description |
|---|---|
| `instance_id` | Kafka instance ID |
| `instance_status` | Cloud-reported instance status |
| `connection_info` | Private and public endpoint metadata returned by the cloud |
| `allow_list_ids` | All bound allowlist IDs |
| `managed_allow_list_ids` | Managed allowlist IDs keyed by input key |
| `topic_names` | Managed Topic names |
| `sasl_user_names` | Managed SASL usernames |
| `consumer_group_ids` | Managed Consumer Group IDs |
| `acl_ids` | Managed ACL Provider IDs, keyed first by logical ACL key and then by CIDR |

## 9. Notes

- VPC, subnet, routing, DNS, and client security groups are caller-owned. This module does not create or import them.
- Broker count is not exposed by the VolcengineCC Kafka instance schema in Provider `0.0.70` or `0.0.71`. Select capacity through `compute_spec`; do not infer broker count from it.
- Instance VPC, subnet, zones, version, storage type, project, billing configuration, and initial allowlist binding are create-only. Changes replace the instance.
- Topic name, instance association, cleanup policy, and tags are create-only. Group identity and tags, user identity and password type, and every ACL field are also create-only.
- Changing a `for_each` map key changes the Terraform resource address and normally recreates that object.
- Kafka user passwords are write-only in Cloud Control but are not marked sensitive by Provider `0.0.71`. They remain in Terraform State. Use an encrypted remote backend with tightly scoped access and avoid exposing plans.
- `partition_capacity`, `need_rebalance`, and initial allowlist IDs are write-only. Confirm the expected behavior of subsequent plans when using these parameters.
- Import is supported by the Provider for all managed resource types, but this module does not automatically adopt existing resources.
- Provider `0.0.71` cannot refresh a `volcenginecc_kafka_acl` whose `ip` contains multiple comma-separated CIDRs. The module preserves the `acls[*].ip` input contract but creates one physical ACL per CIDR, which keeps refresh and subsequent plans stable. Accordingly, `acl_ids` is nested by logical ACL key and CIDR.
