# Complete Kafka Example

## 1. Overview

This example represents a three-AZ Kafka deployment with SASL authentication, private access, event and CDC streams, and TLS log delivery. It creates two SASL/SCRAM users, three Kafka Topics, one Consumer Group, five least-privilege logical ACL rules expanded to ten physical ACLs for two CIDRs, and a TLS Project, Topic, index, and Kafka Shipper.

## 2. Usage

Provide an existing VPC, subnet, exactly three availability zones, private client CIDRs, a region-specific Kafka compute specification, and separate producer and consumer passwords. Configure Volcengine credentials outside source control.

```shell
terraform init
terraform plan
terraform apply
```

## 3. Examples

`application_events` models an event-bus stream. `database_cdc` models a compacted CDC stream. `log_export` receives JSON/Gzip records from the TLS Shipper. The producer can write the event and CDC Topics; the consumer can read both and use only the declared Consumer Group. All ACL rules are restricted to the supplied private CIDRs.

## 4. Requirements

| Name | Version |
|---|---|
| Terraform | `= 1.5.7` |
| VolcengineCC Provider | `>= 0.0.70` |

## 5. Providers

| Name | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 6. Resources

The published Kafka module manages one three-AZ Kafka instance, two allowlists, three Topics, two users, one Consumer Group, and five logical ACL rules. The example's two-CIDR inputs expand to ten physical ACLs. The `private_clients` allowlist contains only application client CIDRs; the `tls_shipper` allowlist permits only `100.64.0.0/10`, the managed TLS Kafka Shipper service network. The example root also manages one TLS Project, source Topic, TLS index with automatic field and full-text indexing enabled, and Kafka Shipper. The Shipper explicitly depends on the index so indexing is enabled before log delivery is created. VPC, subnet, and client security groups are external.

## 7. Inputs

| Name | Sensitive | Description |
|---|---|---|
| `region` | no | Volcengine region |
| `instance_name` | no | Kafka instance name |
| `vpc_id` | no | Existing VPC ID |
| `subnet_id` | no | Existing subnet ID |
| `availability_zone_ids` | no | Exactly three distinct Kafka availability zones |
| `compute_spec` | no | Region-specific Kafka compute specification |
| `private_client_cidrs` | no | Private CIDRs used by the allowlist and ACLs |
| `producer_password` | yes | Producer SASL password |
| `consumer_password` | yes | Consumer SASL password |
| `project_name` | no | Optional IAM project |

## 8. Outputs

The example returns the instance ID, cloud connection metadata, Topic names, SASL usernames, Consumer Group IDs, ACL IDs, and TLS log-delivery resources, index configuration, IDs, and status.

## 9. Notes

- The example does not create VPC, subnet, routing, or client security groups.
- Broker count is unavailable in the Provider schema; `compute_spec` is the available capacity control.
- Every ACL field is create-only. Changing a rule replaces its physical ACL resources.
- User passwords enter Terraform State because Provider `0.0.71` does not mark `user_password` sensitive.
- Provider `0.0.71` cannot reliably refresh a comma-separated multi-CIDR ACL. The module expands each CIDR to an independent ACL to keep refreshes and subsequent plans stable.
- The TLS Kafka Shipper reaches Kafka from the managed service CIDR `100.64.0.0/10`. This CIDR is permitted only by the `tls_shipper` allowlist and is not added to application client ACLs.
