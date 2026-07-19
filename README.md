# terraform-azurerm-devops

Terraform module that provisions the [Azure](https://azure.microsoft.com/)
infrastructure a DevOps pipeline needs to store its remote state: a dedicated
resource group, a hardened storage account (TLS 1.2, blob versioning), and a
private blob container for Terraform/pipeline state.

Azure DevOps organizations and projects are not managed by the `azurerm`
provider, so this module focuses on the concrete, deployable backing resources
rather than the DevOps control plane itself.

## Usage

```hcl
module "devops" {
  source = "github.com/moveeeax/terraform-azurerm-devops"

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

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                       | Description                                                          | Type          | Default      | Required |
|----------------------------|----------------------------------------------------------------------|---------------|--------------|:--------:|
| `name`                     | Base name used to derive the resource group name.                    | `string`      | n/a          |   yes    |
| `location`                 | Azure region in which to create the resources.                       | `string`      | n/a          |   yes    |
| `storage_account_name`     | Globally unique storage account name (3-24 lowercase alnum).         | `string`      | n/a          |   yes    |
| `state_container_name`     | Name of the blob container that stores state.                        | `string`      | `"tfstate"`  |    no    |
| `account_replication_type` | Replication type of the storage account.                             | `string`      | `"LRS"`      |    no    |
| `tags`                     | Map of tags applied to all resources.                                | `map(string)` | `{}`         |    no    |

## Outputs

| Name                   | Description                            |
|------------------------|----------------------------------------|
| `resource_group_name`  | Name of the created resource group.    |
| `storage_account_id`   | ID of the state storage account.       |
| `storage_account_name` | Name of the state storage account.     |
| `state_container_name` | Name of the state blob container.      |

## License

[MIT](LICENSE)
