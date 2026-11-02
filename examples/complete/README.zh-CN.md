# Kafka 完整示例

## 1. 概述

本示例表示三可用区 Kafka 部署，为事件流和 CDC 数据流配置 SASL 鉴权与私网访问，并配置 TLS 日志投递。示例创建两个 SASL/SCRAM 用户、三个 Kafka Topic、一个 Consumer Group、五条最小权限逻辑 ACL（按双 CIDR 展开为十条物理 ACL），以及一个 TLS Project、源 Topic、索引和 Kafka Shipper。

## 2. 用法

需要提供已有 VPC、Subnet、恰好三个可用区、私网客户端 CIDR、地域可售的 Kafka 计算规格，以及相互独立的生产者和消费者密码。火山引擎凭据应在版本控制之外配置。

```shell
terraform init
terraform plan
terraform apply
```

## 3. 示例

`application_events` 表示事件总线数据流，`database_cdc` 表示启用 compact 的 CDC 数据流，`log_export` 接收 TLS Shipper 投递的 JSON/Gzip 日志。生产者可以写入事件和 CDC Topic；消费者可以读取二者，并且只能使用声明的 Consumer Group。全部 ACL 均限制在传入的私网 CIDR 内。

## 4. 版本要求

| 名称 | 版本 |
|---|---|
| Terraform | `= 1.5.7` |
| VolcengineCC Provider | `>= 0.0.70` |

## 5. Provider

| 名称 | Source |
|---|---|
| `volcenginecc` | `volcengine/volcenginecc` |

## 6. 资源

已发布的 Kafka 模块管理一个三可用区 Kafka 实例、两个白名单、三个 Topic、两个用户、一个 Consumer Group 和五条逻辑 ACL。本示例的双 CIDR 输入会展开为十条物理 ACL。`private_clients` 白名单仅放行业务客户端 CIDR；`tls_shipper` 白名单仅放行日志服务投递所需的 `100.64.0.0/10`。示例根模块还管理一个 TLS Project、源 Topic、启用自动字段和全文检索的 TLS 索引，以及 Kafka Shipper。Shipper 显式依赖索引资源，确保日志投递创建前索引已启用。VPC、Subnet 和客户端安全组为外部资源。

## 7. 输入

| 名称 | 敏感 | 说明 |
|---|---|---|
| `region` | 否 | 火山引擎地域 |
| `instance_name` | 否 | Kafka 实例名称 |
| `vpc_id` | 否 | 已有 VPC ID |
| `subnet_id` | 否 | 已有 Subnet ID |
| `availability_zone_ids` | 否 | 恰好三个不同的 Kafka 可用区 |
| `compute_spec` | 否 | 地域可售的 Kafka 计算规格 |
| `private_client_cidrs` | 否 | 白名单和 ACL 使用的私网 CIDR |
| `producer_password` | 是 | 生产者 SASL 密码 |
| `consumer_password` | 是 | 消费者 SASL 密码 |
| `project_name` | 否 | 可选 IAM 项目 |

## 8. 输出

本示例输出实例 ID、云端连接元数据、Topic 名称、SASL 用户名、Consumer Group ID、ACL ID，以及 TLS 日志投递资源、索引配置的 ID 和状态。

## 9. 注意事项

- 本示例不创建 VPC、Subnet、路由或客户端安全组。
- Provider Schema 未提供 Broker 数量，`compute_spec` 是当前可用的容量控制项。
- ACL 的全部字段均为 create-only，修改规则会替换对应 ACL 资源。
- Provider `0.0.71` 未将 `user_password` 标记为 sensitive，因此用户密码会进入 Terraform State。
- Provider `0.0.71` 无法稳定回读逗号拼接多 CIDR 的单条 ACL。模块将每个 CIDR 展开为独立 ACL，以保持 refresh 和后续 Plan 稳定。
- TLS Kafka Shipper 从托管服务网段 `100.64.0.0/10` 访问 Kafka。该网段仅在 `tls_shipper` 白名单中放行，不加入业务客户端 ACL。
