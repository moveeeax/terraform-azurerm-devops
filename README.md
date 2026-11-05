# terraform-azurerm-devops

Terraform module that provisions the [Azure](https://azure.microsoft.com/)
infrastructure a DevOps pipeline needs to store its remote state: a dedicated
resource group, a hardened storage account (TLS 1.2, blob versioning), and a
private blob container for Terraform/pipeline state.

Azure DevOps organizations and projects are not managed by the `azurerm`
provider, so this module focuses on the concrete, deployable backing resources
rather than the DevOps control plane itself.

## Security posture

The state account is configured for a secret-bearing workload, not for general
file serving:

- `allow_nested_items_to_be_public = false` — anonymous public read cannot be
  turned on for any container or blob in the account, even by someone who
  later creates a container outside this module.
- `container_access_type = "private"` on the state container.
- `min_tls_version = "TLS1_2"` and HTTPS-only traffic.
- Blob versioning plus 7-day soft delete for both blobs and containers, so an
  overwritten, deleted or destroyed state file is recoverable.
- `public_network_access_enabled` is exposed as a variable so the account can
  be reached exclusively over a private endpoint.

The module takes no credentials of any kind as input — no PAT, no service
connection secret, no storage access key — so there is nothing here to leak
into state or into a plan output.

## Usage

```hcl
module "devops" {
  source = "github.com/moveeeax/terraform-azurerm-devops?ref=v1.0.0"

  name                 = "platform"
  location             = "eastus"
  storage_account_name = "platformdevopssa01"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version          |
|-----------|------------------|
| terraform | >= 1.5           |
| azurerm   | >= 4.9, < 6.0    |

`azurerm_storage_container.storage_account_id` only exists from azurerm
4.9.0 onwards, so older provider versions cannot plan this module at all. CI
runs against the latest 5.x release; 6.x is excluded until it has been tested.

## Inputs

| Name                              | Description                                                                    | Type          | Default      | Required |
|-----------------------------------|--------------------------------------------------------------------------------|---------------|--------------|:--------:|
| `name`                            | Base name used to derive the resource group name.                              | `string`      | n/a          |   yes    |
| `location`                        | Azure region in which to create the resources.                                 | `string`      | n/a          |   yes    |
| `storage_account_name`            | Globally unique storage account name (3-24 lowercase alnum).                   | `string`      | n/a          |   yes    |
| `state_container_name`            | Name of the blob container that stores state.                                  | `string`      | `"tfstate"`  |    no    |
| `account_replication_type`        | Replication type. One of `LRS`, `ZRS`, `GRS`, `RAGRS`, `GZRS`, `RAGZRS`.       | `string`      | `"LRS"`      |    no    |
| `public_network_access_enabled`   | Whether the account is reachable from the public internet.                     | `bool`        | `true`       |    no    |
| `blob_soft_delete_retention_days` | Days deleted blobs and containers stay recoverable (1-365).                    | `number`      | `7`          |    no    |
| `tags`                            | Map of tags applied to all resources.                                          | `map(string)` | `{}`         |    no    |

## Outputs

| Name                   | Description                            |
|------------------------|----------------------------------------|
| `resource_group_name`  | Name of the created resource group.    |
| `storage_account_id`   | ID of the state storage account.       |
| `storage_account_name` | Name of the state storage account.     |
| `state_container_name` | Name of the state blob container.      |

## Tests

The suite in [`tests/`](tests) uses `mock_provider`, so it runs with no Azure
credentials and no cloud calls:

```sh
terraform init -backend=false
terraform test
```

`mock_provider` requires Terraform (or OpenTofu) >= 1.7. That is a test-only
requirement — the module itself still supports >= 1.5.

## License

[MIT](LICENSE)
