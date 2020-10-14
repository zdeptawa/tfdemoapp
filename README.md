# tfdemoapp
Very basic sample Terraform configuration using the AzureRM Terraform Provider. 

# Prerequisites
Before you can use this code, you'll need to gather and configure your Azure Authentication info(`client_id`, `client_secret`, `tenant_id`, `subscription_id`). While you can use your own personal authentication information, it is suggested that you use an Azure Service Principal instead. [How to create a Service Principal for use with Terraform can be found here](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html). 

You will also need Terraform and Git installed on your system. If you don't yet have Terraform installed, [this guide will help you get it set up](https://www.terraform.io/intro/getting-started/install.html). If you still need to install Git, [you can download it here](https://git-scm.com/downloads).

# Usage
To use/test this code, do the following:

1. Clone this repository.
2. Change directory to this demo folder.
3. Configure your Azure Authentication information (client_id, client_secret, tenant_id, subscription_id) via Terraform variables or - the preferred method - environment variables.
4. Run `terraform init` to initialize the Terraform environment in this directory and pull down required providers and modules.
5. Run `terraform plan` to plan the changes and build the dependency graphs required. This will also allow you to see what changes will occur before applying.
6. **ONLY IF ALL LOOKS WELL ON THE PLAN**, run `terraform apply` to apply your changes.
7. If you'd like to tear this infrastructure back down, run `terraform destroy` to tear it back down. ***IMPORTANT*** This is a destructive step that *will* tear down infrastructure that you've built. Make sure you want to do that before running this command!

# More Information
Docs on Terraform.io -> [https://www.terraform.io/docs/providers/azurerm/](https://www.terraform.io/docs/providers/azurerm/)

Docs on Microsoft -> [https://aka.ms/az-tf-docs](https://aka.ms/az-tf-docs)