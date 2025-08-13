# Create Resource group
resource "azurerm_resource_group" "appgrp" {
  name     = var.rgname
  location = var.location
}

# Create Virtual Network & Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.rgname
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = var.rgname
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace
  resource_group_name = var.rgname
  location            = var.location
  friendly_name       = "${var.prefix} Workspace"
  description         = "${var.prefix} Workspace"
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                    = var.hostpool
  location                = var.location
  resource_group_name     = var.rgname
  friendly_name           = var.hostpool
  validate_environment    = true
  custom_rdp_properties   = "audiocapturemode:i:1;audiomode:i:0;"
  description             = "${var.prefix} Terraform HostPool"
  type                    = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type      = "DepthFirst"
}

# Host pool registration info
resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = var.rfc3339
}

# Create AVD Desktop App Group (DAG)
resource "azurerm_virtual_desktop_application_group" "dag" {
  name                = var.dag
  resource_group_name = var.rgname
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool.id
  location            = var.location
  type                = "Desktop"
  friendly_name       = "Desktop AppGroup"
  description         = "AVD application group"
  depends_on = [
    azurerm_virtual_desktop_workspace.workspace,
    azurerm_virtual_desktop_host_pool.hostpool
  ]
}

# Associate DAG to Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
}

# Create Public IP for VM (optional)
resource "azurerm_public_ip" "vm_pip" {
  name                = "${var.prefix}-pip"
  location            = var.location
  resource_group_name = var.rgname
  allocation_method   = "Dynamic"
}

# Create NIC for VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.prefix}-nic"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

# Create a Windows VM as AVD Session Host
resource "azurerm_windows_virtual_machine" "session_host" {
  name                = "${var.prefix}-vm01"
  resource_group_name = var.rgname
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = "avdadmin"
  admin_password      = "P@ssw0rd1234!"  # Replace with a secret reference or key vault in production
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]
  provision_vm_agent   = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-avd"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Role = "AVD-SessionHost"
  }

  depends_on = [azurerm_virtual_desktop_host_pool_registration_info.registrationinfo]
}

# AVD Agent Extension to Register VM to Host Pool
resource "azurerm_virtual_machine_extension" "avd_agent" {
  name                 = "avd-agent"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host.id
  publisher            = "Microsoft.HybridCompute"
  type                 = "MicrosoftMonitoringAgent"
  type_handler_version = "1.0"

  settings = jsonencode({
    "registrationInfoToken" = azurerm_virtual_desktop_host_pool_registration_info.registrationinfo.token
  })

  depends_on = [azurerm_windows_virtual_machine.session_host]
}
