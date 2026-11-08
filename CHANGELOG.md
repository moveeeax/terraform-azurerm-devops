# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- `backend_config` output: map of `subscription_id`, `resource_group_name`,
  `storage_account_name`, `container_name` and `use_azuread_auth` for a
  `backend "azurerm"` block pointing at the state container.
- `backend_config_hcl` output: the same settings rendered as a partial backend
  configuration file for `terraform init -backend-config=backend.hcl`.
- `backend_use_azuread_auth` input (default `false`) sets `use_azuread_auth` in
  those outputs. It changes no resource.
- `state_writer_principal_ids` and `state_reader_principal_ids` inputs (maps of
  label to Entra ID object ID, default `{}`) create Storage Blob Data
  Contributor and Storage Blob Data Reader role assignments scoped to the state
  container. Values must be GUIDs.
- `shared_access_key_enabled` input, default `true` (the provider default, so
  existing accounts plan unchanged). When `false`, the backend outputs always
  set `use_azuread_auth = true`.
- `state_container_resource_manager_id` output: ARM ID of the state container.

## [1.1.0] - 2026-11-05

### Fixed

- Block anonymous public access on the state account
  (`allow_nested_items_to_be_public = false`) and correct the azurerm floor to
  4.9, the first version with `azurerm_storage_container.storage_account_id`.

### Added

- Blob and container soft delete (`blob_soft_delete_retention_days`, default 7),
  `public_network_access_enabled` input, explicit HTTPS-only traffic, input
  validation and a `mock_provider` test suite.

### Changed

- Allow azurerm 5.x (`>= 4.9, < 6.0`).
- CI: group Dependabot updates monthly and auto-merge patch updates; refresh
  action versions.

## [1.0.0] - 2026-07-26

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-devops/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-azurerm-devops/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-devops/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-devops/releases/tag/v1.0.0
