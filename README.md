# Create a secure Ubuntu virtual desktop

![Azure](https://img.shields.io/badge/azure-%230072C6.svg?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Terraform Cloud](https://img.shields.io/badge/terraform%20cloud-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

This is a simple terraform hcl to create a virtual linux machine using `minimal-22_04-lts-gen2` from Canonical with the simplest (cheapest) settings on the VM. I also used a somewhat cheap SKU for this machine without temp storage. The intention was to build a very lightweight Ubuntu virtual desktop with a minimal set of tools installed.

This example also uses Terraform Cloud for backend state file management.

## Prerequisites

- You need an Azure account and if you don't have one, get a [free one here](https://azure.microsoft.com/en-us/free/).

- Create a service principal (replace [ServicePrincipalName] with a name and [subscription-id] with your id) and copy the JSON output:

    ```bash
    az ad sp create-for-rbac --name [ServicePrincipalName] --role Contributor --scopes /subscriptions/[subscription-id] --sdk-auth
    ```

- Create a local backend file:
  1. Create a terraform [API token](https://app.terraform.io/app/settings/tokens).
  2. Create a new [Terraform Cloud](https://app.terraform.io/) workspace.
  3. Create a terraform backend file, e.g. `config-terraform.tfbackend`. **(Make sure to NOT commit this file in your repo!!)**

        ```text
        hostname     = "app.terraform.io"
        organization = "[your-terraform-cloud-organization]"
        workspaces { name = "[your-newly-created-workspace]" }
        token = "[your-terraform-api-token]"
        ```

- Create variables in your Terraform Cloud workspace (values from the json output)
  1. ARM_CLIENT_ID = [clientId]
  2. ARM_CLIENT_SECRET = [clientSecret] **Mark it as sensitive**
  3. ARM_SUBSCRIPTION_ID = [subscriptionId]
  4. ARM_TENANT_ID = [tenantId]

- Remember to set variable `client_ip` to whitelist your workstation ip to get access to the VM and if you don't want to change the variables in `variables.tf` you can use a `terraform.tfvars` file to set the variables.

## Execution

1. Execute below terraform commands to deploy the virtual machine

    ```bash
    terraform init -backend-config=config.terraform.tfbackend
    terraform fmt
    terraform validate
    terraform plan
    terraform apply
    ```

## Resources

[Terraform: azurerm_linux_virtual_machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine)

[MS Learn: Quickstart - Create a Linux virtual machine in the Azure portal](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu)

[MS Learn: Quickstart - Use Terraform to create a Linux VM](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-terraform)
