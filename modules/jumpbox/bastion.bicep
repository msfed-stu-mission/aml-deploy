@description('The Azure region where the Bastion should be deployed')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object

@description('Virtual network name')
param p_vnetName string

@description('The address prefix to use for the Bastion subnet')
param p_addressPrefix string = '192.168.250.0/27'

@description('The name of the Bastion public IP address')
param p_publicIpName string = 'pip-bastion'

@description('The name of the Bastion host')
param p_bastionHostName string = 'bastion-jumpbox'

// The Bastion Subnet is required to be named 'AzureBastionSubnet'
var subnetName = 'AzureBastionSubnet'

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${p_vnetName}/${subnetName}'
  properties: {
    addressPrefix: p_addressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

resource publicIpAddressForBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: p_publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: p_bastionHostName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastionHost.id
