# Basic Kafka Example

## 1. Overview

This example represents a basic private Kafka cluster for an event bus or asynchronous worker pipeline. It creates one allowlist, one SASL/SCRAM user, one Topic with three replicas, and one Consumer Group.

## 2. Usage

Provide an existing VPC, subnet, availability zone, private application CIDR, a region-specific Kafka compute specification, and a SASL password. Configure Volcengine credentials outside the files committed to source control.

```shell
terraform init
terraform plan
terraform apply
```

## 3. Examples

The configuration models a basic cluster plus Topic and user. The user receives broad Topic authority to keep the first example small; use explicit ACLs as shown by the complete scenario for least-privilege workloads.

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

The example consumes the published Kafka module, which manages one Kafka instance, allowlist, Topic, SASL user, and Consumer Group. VPC, subnet, and client security groups are external.

## 7. Inputs

| Name | Sensitive | Description |
|---|---|---|
| `region` | no | Volcengine region |
| `instance_name` | no | Kafka instance name |
| `vpc_id` | no | Existing VPC ID |
| `subnet_id` | no | Existing subnet ID |
| `availability_zone_id` | no | Kafka availability zone |
| `compute_spec` | no | Region-specific Kafka compute specification |
| `application_cidr` | no | Private CIDR permitted to connect |
| `sasl_password` | yes | Password for the basic SASL user |

## 8. Outputs

The example returns the instance ID, cloud connection metadata, Topic names, and Consumer Group IDs.

## 9. Notes

- The example does not create VPC, subnet, routing, or client security groups.
- The Provider exposes no Kafka security-group association field.
- The SASL password enters Terraform State because Provider `0.0.71` does not mark `user_password` sensitive.
