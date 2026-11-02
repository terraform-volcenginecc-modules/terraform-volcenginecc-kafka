# VolcengineCC Kafka 模块

## 1. 概述

本 Terraform 模块创建私网访问的火山引擎托管 Kafka 集群，适用于事件总线、日志管道、变更数据捕获（CDC）、异步解耦和实时数据流。模块管理 Kafka 实例、白名单、Topic、SASL 用户、Consumer Group 和 ACL 规则。

调用方负责 VPC、Subnet 和客户端安全组。当前 Provider 接受 VPC 和 Subnet ID，但没有提供 Kafka 安全组关联字段，因此客户端安全组规则不由本模块管理。

## 2. 用法

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

Provider 凭据和地域由调用方根模块配置。

## 3. 示例

`basic` 场景表示一个基础私网集群，包含一个 Topic、一个 SASL 用户和一个 Consumer Group，可用于事件总线或异步 Worker 管道。

`complete` 场景表示三可用区部署，为事件流和 CDC 数据流配置 SASL 鉴权与私网访问，并将 TLS 日志投递到专用 Kafka Topic，同时分别配置生产者、消费者和 Consumer Group ACL。

日志管道、CDC 和 ACL 不新增独立场景目录，因为两套必需示例已经覆盖这些任务。

## 4. 版本要求

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| VolcengineCC Provider | `>= 0.0.70` |

最低版本采用 `0.0.70`，因为该版本包含本模块使用的全部六类 Kafka 资源，包括 Kafka ACL。

## 5. Provider

| 名称 | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 6. 资源

| 资源 | 用途 |
|---|---|
| `volcenginecc_kafka_instance.this` | 托管 Kafka 集群和私网接入点 |
| `volcenginecc_kafka_allow_list.this` | 私网客户端白名单 |
| `volcenginecc_kafka_topic.this` | Topic、分区、副本和保留策略 |
| `volcenginecc_kafka_user.this` | SASL/PLAIN 或 SASL/SCRAM 用户 |
| `volcenginecc_kafka_group.this` | Consumer Group |
| `volcenginecc_kafka_acl.this` | Topic 和 Group ACL 规则 |

## 7. 输入

| 名称 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `instance_name` | `string` | 无 | Kafka 实例名称 |
| `instance_description` | `string` | `null` | Kafka 实例描述 |
| `vpc_id` | `string` | 无 | 已有 VPC ID |
| `subnet_id` | `string` | 无 | 已有 Subnet ID |
| `availability_zone_ids` | `list(string)` | 无 | 一个或多个可用区 |
| `compute_spec` | `string` | 无 | 地域可售的 Kafka 计算规格 |
| `kafka_version` | `string` | `"2.8.2"` | Kafka 引擎版本 |
| `storage_space_gib` | `number` | 无 | 存储容量，单位 GiB，必须为 100 的倍数 |
| `storage_type` | `string` | `"ESSD_FlexPL"` | Kafka 云盘类型 |
| `partition_capacity` | `number` | `null` | 可选的 write-only 已购分区容量 |
| `need_rebalance` | `bool` | `null` | 可选的 write-only 重平衡请求 |
| `instance_parameters` | `object` | 文档默认值 | 消息大小、消息保留、位点保留和时间戳配置 |
| `allow_list_ids` | `set(string)` | `[]` | 已有白名单 ID |
| `allow_lists` | `map(object)` | `{}` | 以稳定逻辑标识为 key 的托管白名单 |
| `sasl_users` | `map(object)` | `{}` | 以实际用户名为 key 的托管用户 |
| `sasl_user_passwords` | `map(string)` | `{}` | 与 `sasl_users` 使用相同 key 的敏感密码映射 |
| `topics` | `map(object)` | `{}` | 以实际 Topic 名称为 key 的托管 Topic |
| `consumer_groups` | `map(object)` | `{}` | 以实际 Group ID 为 key 的托管 Consumer Group |
| `acls` | `map(object)` | `{}` | 以稳定逻辑标识为 key 的 create-only ACL 规则 |
| `charge_type` | `string` | `"PostPaid"` | `PostPaid` 或 `PrePaid` 计费方式 |
| `purchase_period` | `number` | `null` | 预付费购买时长 |
| `purchase_period_unit` | `string` | `null` | 预付费时长单位 |
| `auto_renew` | `bool` | `false` | 预付费自动续费 |
| `project_name` | `string` | `null` | 火山引擎 IAM 项目 |
| `tags` | `map(string)` | `{}` | Kafka 实例标签 |

必须至少配置一个托管或外部白名单。模块拒绝全网开放的白名单和 ACL IP 规则。

## 8. 输出

| 名称 | 说明 |
|---|---|
| `instance_id` | Kafka 实例 ID |
| `instance_status` | 云端返回的实例状态 |
| `connection_info` | 云端返回的私网和公网接入点元数据 |
| `allow_list_ids` | 绑定的全部白名单 ID |
| `managed_allow_list_ids` | 按输入 key 返回的托管白名单 ID |
| `topic_names` | 托管 Topic 名称 |
| `sasl_user_names` | 托管 SASL 用户名 |
| `consumer_group_ids` | 托管 Consumer Group ID |
| `acl_ids` | 托管 ACL 的 Provider ID，先按逻辑 ACL key、再按 CIDR 索引 |

## 9. 注意事项

- VPC、Subnet、路由、DNS 和客户端安全组由调用方管理，本模块不创建或导入这些资源。
- VolcengineCC Provider `0.0.70` 和 `0.0.71` 的 Kafka 实例 Schema 均未提供 Broker 数量字段。容量通过 `compute_spec` 选择，不能据此推断 Broker 数量。
- 实例 VPC、Subnet、可用区、版本、存储类型、项目、计费配置和初始白名单绑定均为 create-only，变更会替换实例。
- Topic 名称、实例关联、清理策略和标签为 create-only。Group 标识与标签、用户标识与密码类型以及 ACL 全部字段也均为 create-only。
- 修改 `for_each` map key 会改变 Terraform 资源地址，通常会重建对应对象。
- Kafka 用户密码在 Cloud Control 中是 write-only，但 Provider `0.0.71` 未将其标记为 sensitive，因此密码会保留在 Terraform State 中。必须使用加密且严格控制访问权限的远端 Backend，并避免暴露 Plan。
- `partition_capacity`、`need_rebalance` 和初始白名单 ID 为 write-only；使用这些参数时应确认后续 Plan 的预期行为。
- Provider 支持导入全部托管资源类型，但本模块不会自动接管已有资源。
- Provider `0.0.71` 无法稳定回读 `ip` 为逗号拼接多 CIDR 的 `volcenginecc_kafka_acl`。模块保持 `acls[*].ip` 的输入契约，但会按 CIDR 创建物理 ACL，以保证 refresh 和二次 plan 稳定。因此 `acl_ids` 按逻辑 ACL key 和 CIDR 两层索引。
