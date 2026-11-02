# Kafka 基础示例

## 1. 概述

本示例表示用于事件总线或异步 Worker 管道的基础私网 Kafka 集群，创建一个白名单、一个 SASL/SCRAM 用户、一个三副本 Topic 和一个 Consumer Group。

## 2. 用法

需要提供已有 VPC、Subnet、可用区、私网应用 CIDR、地域可售的 Kafka 计算规格和 SASL 密码。火山引擎凭据应在版本控制文件之外配置。

```shell
terraform init
terraform plan
terraform apply
```

## 3. 示例

本配置表达“基础集群、Topic 与用户”场景。为保持首个示例精简，用户拥有较宽泛的 Topic 权限；最小权限工作负载应采用 complete 场景中的显式 ACL。

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

本示例调用已发布的 Kafka 模块，由模块管理一个 Kafka 实例、白名单、Topic、SASL 用户和 Consumer Group。VPC、Subnet 和客户端安全组均为外部资源。

## 7. 输入

| 名称 | 敏感 | 说明 |
|---|---|---|
| `region` | 否 | 火山引擎地域 |
| `instance_name` | 否 | Kafka 实例名称 |
| `vpc_id` | 否 | 已有 VPC ID |
| `subnet_id` | 否 | 已有 Subnet ID |
| `availability_zone_id` | 否 | Kafka 可用区 |
| `compute_spec` | 否 | 地域可售的 Kafka 计算规格 |
| `application_cidr` | 否 | 允许连接的私网 CIDR |
| `sasl_password` | 是 | 基础 SASL 用户密码 |

## 8. 输出

本示例输出实例 ID、云端连接元数据、Topic 名称和 Consumer Group ID。

## 9. 注意事项

- 本示例不创建 VPC、Subnet、路由或客户端安全组。
- Provider 未提供 Kafka 安全组关联字段。
- Provider `0.0.71` 未将 `user_password` 标记为 sensitive，因此 SASL 密码会进入 Terraform State。
