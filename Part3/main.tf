variable "vm_instance_count" {
  description = "Specify the number of vm instances."
  type        = number
  default     = 3
}

resource "azurerm_resource_group" "rg" {
  name      = "t3rr4f0rm-rg"
  location  = "eastus"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "t3rr4f0rm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "t3rr4f0rm-vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
  name                 = "t3rr4f0rm-sn"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "publicIPs" {
  count               = var.vm_instance_count
  name                = "t3rr4f0rm-ip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
  count               = var.vm_instance_count
  name                = "t3rr4f0rm-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    public_ip_address_id          = azurerm_public_ip.publicIPs[count.index].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.myterraformsubnet.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  count                     = var.vm_instance_count
  network_interface_id      = azurerm_network_interface.myterraformnic[count.index].id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Create virtual machines
resource "azurerm_linux_virtual_machine" "myterraformvm" {
  count                 = var.vm_instance_count
  name                  = "t3rr4f0rm-vm-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.myterraformnic[count.index].id]
  size                  = "Standard_B2s"

  os_disk {
    name                 = "t3rr4f0rm-os-disk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "t3rr4f0rm-vm-${count.index}"
  admin_username                  = "azureuser"
  admin_password                  = "Adm1nP@55w0rd"
  disable_password_authentication = false
}

// Create SQL Server database
resource "azurerm_sql_server" "example" {
  name                         = "t3rr4f0rmsqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "MyAdministrator"
  administrator_login_password = "Adm1nP@55w0rd"
}