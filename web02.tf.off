# Create web02 server

# Create a network interface for the server
resource "azurerm_network_interface" "tfdemo_network_interface_web02" {
  name                      = "tfdemo_network_interface_web02"
  location                  = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name       = azurerm_resource_group.tfdemo_resource_group.name

  ip_configuration {
    name                                    = "tfdemo_ip_configuration_web02"
    subnet_id                               = azurerm_subnet.tfdemo_public_subnet.id
    private_ip_address_allocation           = "dynamic"
  }

  tags = { environment = "demo", build = "tfdemo" }
}

# Associate this web server's network interface with the backend address pool
resource "azurerm_network_interface_backend_address_pool_association" "tfdemo_backend_pool_association_web02" {
  network_interface_id    = azurerm_network_interface.tfdemo_network_interface_web02.id
  ip_configuration_name   = "tfdemo_ip_configuration_web02"
  backend_address_pool_id = azurerm_lb_backend_address_pool.tfdemo_backend_pool.id
}

# Create a managed disk for our web server
resource "azurerm_managed_disk" "tfdemo_managed_disk_web02" {
  name                 = "tfdemo_managed_disk_web02"
  location             = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name  = azurerm_resource_group.tfdemo_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"

  tags = { environment = "demo", build = "tfdemo" }
}

# Create web02
resource "azurerm_virtual_machine" "tfdemo_web02" {
  name                  = "tfdemo_web02"
  location              = azurerm_resource_group.tfdemo_resource_group.location
  resource_group_name   = azurerm_resource_group.tfdemo_resource_group.name
  network_interface_ids = [azurerm_network_interface.tfdemo_network_interface_web02.id]
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
    name              = "tfdemo_storage_os_disk_web02"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = azurerm_managed_disk.tfdemo_managed_disk_web02.name
    managed_disk_id = azurerm_managed_disk.tfdemo_managed_disk_web02.id
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = azurerm_managed_disk.tfdemo_managed_disk_web02.disk_size_gb
  }

  os_profile {
    computer_name  = "tfdemoweb02"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = { environment = "demo", build = "tfdemo" }
}

# Run post provisioning steps so server can allow traffic
resource "azurerm_virtual_machine_extension" "tfdemo_web02_build" {
  name                 = "tfdemo_web02_build"
  virtual_machine_id   = azurerm_virtual_machine.tfdemo_web02.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update -y && sudo apt-get install nginx -y && echo tfdemo-web02 > /var/www/html/index.html"
    }
SETTINGS

  tags = { environment = "demo", build = "tfdemo" }
}