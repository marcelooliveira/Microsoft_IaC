@description('Number of Virtual Machines to Provision')
param virtualMachineCount int = 3

@description('Location for all resources.')
param location string = resourceGroup().location

// Create Network Security Group and rule
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'b1c3p-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1001
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Create virtual network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'b1c3p-vn'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'b1c3p-sn'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Create public IPs
resource publicIPAddresses 'Microsoft.Network/publicIPAddresses@2021-02-01' = [for i in range(0, virtualMachineCount): {
  name: 'b1c3p-ip-${i}'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
}]

// Create network interface
resource networkInterfaces 'Microsoft.Network/networkInterfaces@2020-08-01' = [for i in range(0, virtualMachineCount): {
  name: 'b1c3p-nic-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: publicIPAddresses[i].id
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'b1c3p-sn')
          }
        }
      }
    ]
  }
}]

// Create virtual machines
resource virtualMachines 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(0, virtualMachineCount): {
    name: 'b1c3p-vm-${i}'
    location: location
    properties:{
      hardwareProfile: {
        vmSize:'Standard_B2s'
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }        
      }
      osProfile: {
        computerName: 'b1c3p-vm-${i}'
        adminUsername: 'azureuser'
        adminPassword: 'Adm1nP@55w0rd'
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: networkInterfaces[i].id
          }
        ]
      }
    }
  }]

// Create PostgreSQL Server database
resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'b1c3ppostgresql'
  location: location
  sku: {
    name: 'GP_Gen5_2'
    tier: 'GeneralPurpose'
    capacity: 2
    size: '51200'
    family: 'Gen5'
  }
  properties: {
    createMode: 'Default'
    version: '11'
    administratorLogin: 'MyAdministrator'
    administratorLoginPassword: 'Adm1nP@55w0rd'
    storageProfile: {
      storageMB: 51200
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }

  resource virtualNetworkRule 'virtualNetworkRules@2017-12-01' = {
    name: 'AllowSubnet'
    properties: {
      virtualNetworkSubnetId: virtualNetwork.properties.subnets[0].id
      ignoreMissingVnetServiceEndpoint: true
    }
  }
}
