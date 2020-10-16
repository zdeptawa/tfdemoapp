# This is an example of a basic Terraform configuration file that sets up a new demo resource group,
# and creates a new demo network with a web server in a public subnet behind a load balancer.
# Renaming 'web02.tf.off' and running 'terraform apply' will also stand up a second web server in
# the same public subnet, behind the same load balancer.

# IMPORTANT: Make sure subscription_id, client_id, client_secret, and tenant_id are configured!

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "tfdemo_resource_group" {
  name     = "tfdemo_resource_group"
  location = "westus2"

  tags = { environment = "demo", build = "tfdemo" }
}

# Create a virtual network
resource "azurerm_virtual_network" "tfdemo_network" {
  name                = "tfdemo_network"
  location            = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name
  address_space       = ["10.0.0.0/16"]
  
  tags = { environment = "demo", build = "tfdemo" }
}

# Create a public subnet
resource "azurerm_subnet" "tfdemo_public_subnet" {
  name                      = "tfdemo_public_subnet"
  address_prefixes          = ["10.0.1.0/24"]
  resource_group_name       = azurerm_resource_group.tfdemo_resource_group.name
  virtual_network_name      = azurerm_virtual_network.tfdemo_network.name
}

# Create a private subnet
resource "azurerm_subnet" "tfdemo_private_subnet" {
  name                      = "tfdemo_private_subnet"
  address_prefixes          = ["10.0.2.0/24"]
  resource_group_name       = azurerm_resource_group.tfdemo_resource_group.name
  virtual_network_name      = azurerm_virtual_network.tfdemo_network.name
}

# Create a security group for the public subnet to allow port 80 traffic
resource "azurerm_network_security_group" "tfdemo_public_security_group" {
  name                = "tfdemo_public_security_group"
  location            = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name

  security_rule {
    name                       = "tfdemo_allow_web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = { environment = "demo", build = "tfdemo" }
}

# Associate public security group with public subnet
resource "azurerm_subnet_network_security_group_association" "tfdemo_public_sg_association" {
  subnet_id                 = azurerm_subnet.tfdemo_public_subnet.id
  network_security_group_id = azurerm_network_security_group.tfdemo_public_security_group.id
}

# Create a network interface for the server
resource "azurerm_network_interface" "tfdemo_network_interface_web01" {
  name                      = "tfdemo_network_interface_web01"
  location                  = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name       = azurerm_resource_group.tfdemo_resource_group.name

  ip_configuration {
    name                                    = "tfdemo_ip_configuration_web01"
    subnet_id                               = azurerm_subnet.tfdemo_public_subnet.id
    private_ip_address_allocation           = "dynamic"
  }

  tags = { environment = "demo", build = "tfdemo" }
}

# Create a public IP for the load balancer
resource "azurerm_public_ip" "tfdemo_lb_public_ip" {
  name                = "tfdemo_lb_public_ip"
  location            = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name
  allocation_method   = "Static"
}

# Create the load balancer
resource "azurerm_lb" "tfdemo_lb" {
  name                = "tfdemo_lb"
  location            = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.tfdemo_lb_public_ip.id
  }

  tags = { environment = "demo", build = "tfdemo" }
}

# Create a backend pool for the load balancer
resource "azurerm_lb_backend_address_pool" "tfdemo_backend_pool" {
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name
  loadbalancer_id     = azurerm_lb.tfdemo_lb.id
  name                = "tfdemo_backend_pool"
}

# Associate network interface for web01 with the load balancer backend pool
resource "azurerm_network_interface_backend_address_pool_association" "tfdemo_backend_pool_association_web01" {
  network_interface_id    = azurerm_network_interface.tfdemo_network_interface_web01.id
  ip_configuration_name   = "tfdemo_ip_configuration_web01"
  backend_address_pool_id = azurerm_lb_backend_address_pool.tfdemo_backend_pool.id
}

# Create load balancer health probe for port 80
resource "azurerm_lb_probe" "tfdemo_lb_probe" {
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name
  loadbalancer_id     = azurerm_lb.tfdemo_lb.id
  name                = "http-running-probe"
  port                = 80
}

# Create load balancer port 80 rule
resource "azurerm_lb_rule" "tfdemo_lb_rule" {
  resource_group_name            = azurerm_resource_group.tfdemo_resource_group.name
  loadbalancer_id                = azurerm_lb.tfdemo_lb.id
  name                           = "tfdemo_lb_rule"
  protocol                       = "Tcp"
  frontend_port                  = "80"
  backend_port                   = "80"
  frontend_ip_configuration_name = "primary"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.tfdemo_backend_pool.id
  probe_id                       = azurerm_lb_probe.tfdemo_lb_probe.id
}

# Create an availability set for our VMs
resource "azurerm_availability_set" "tfdemo_availability_set" {
  name                = "tfdemo_availability_set"
  location            = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name = azurerm_resource_group.tfdemo_resource_group.name

  tags = { environment = "demo", build = "tfdemo" }
}

# Create a managed disk for our web server
resource "azurerm_managed_disk" "tfdemo_managed_disk_web01" {
  name                 = "tfdemo_managed_disk_web01"
  location             = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name  = azurerm_resource_group.tfdemo_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"

  tags = { environment = "demo", build = "tfdemo" }
}

# Create web01
resource "azurerm_virtual_machine" "tfdemo_web01" {
  name                  = "tfdemo_web01"
  location              = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name   = azurerm_resource_group.tfdemo_resource_group.name
  network_interface_ids = [azurerm_network_interface.tfdemo_network_interface_web01.id]
  vm_size               = "Standard_B1s"
  availability_set_id   = azurerm_availability_set.tfdemo_availability_set.id

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "tfdemo_storage_os_disk_web01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = azurerm_managed_disk.tfdemo_managed_disk_web01.name
    managed_disk_id = azurerm_managed_disk.tfdemo_managed_disk_web01.id
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = azurerm_managed_disk.tfdemo_managed_disk_web01.disk_size_gb
  }

  os_profile {
    computer_name  = "tfdemoweb01"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = { environment = "demo", build = "tfdemo" }
}

# Run post provisioning steps so server can allow traffic
resource "azurerm_virtual_machine_extension" "tfdemo_web01_build" {
  name                 = "tfdemo_web01_build"
  virtual_machine_id   = azurerm_virtual_machine.tfdemo_web01.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update -y && sudo apt-get install nginx -y && echo tfdemo-web01 > /var/www/html/index.html"
    }
SETTINGS

  tags = { environment = "demo", build = "tfdemo" }
}