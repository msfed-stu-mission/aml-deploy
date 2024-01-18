@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Name of the virtual network resource')
param p_virtualNetworkName string

@description('Group ID of the network security group')
param p_networkSecurityGroupId string

@description('Virtual network address prefix')
param p_vnetAddressPrefix string = '192.168.0.0/16'

@description('Training subnet address prefix')
param p_trainingSubnetPrefix string = '192.168.0.0/24'

@description('Scoring subnet address prefix')
param p_scoringSubnetPrefix string = '192.168.1.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: p_virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        p_vnetAddressPrefix
      ]
    }
    subnets: [
      { 
        name: 'SNET-Train'
        properties: {
          addressPrefix: p_trainingSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: p_networkSecurityGroupId
          }
        }
      }
      { 
        name: 'SNET-Score'
        properties: {
          addressPrefix: p_scoringSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.ContainerRegistry'
            }
            {
              service: 'Microsoft.Storage'
            }
          ]
          networkSecurityGroup: {
            id: p_networkSecurityGroupId
          }
        }
      }
    ]
  }
}

output id string = virtualNetwork.id
output name string = virtualNetwork.name
