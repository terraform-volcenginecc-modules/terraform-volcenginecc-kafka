# Changelog

All notable changes to this module are documented in this file.

## [Unreleased]

### Added

- Initial Kafka module implementation.
- Managed Kafka instance, allowlist, Topic, SASL user, Consumer Group, and ACL resources.
- Basic and complete private Kafka examples with bilingual documentation.
- Input validation for private allowlists, ACLs, Topic topology, and SASL credentials.
- Three-AZ complete example with TLS-to-Kafka log delivery.
- Real-cloud validation fixtures for inventory, endpoint connectivity, and post-destroy absence checks.

### Changed

- Pinned Terraform to `1.5.7`.
- Explicitly managed cloud-returned Kafka instance parameter defaults to prevent second-plan drift.
- Expanded comma-separated ACL CIDRs into stable single-CIDR provider resources, avoiding the Provider `0.0.71` multi-CIDR ACL refresh defect.
