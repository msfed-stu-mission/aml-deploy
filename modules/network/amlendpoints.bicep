@description('Azure region of the deployment')
param location string

@description('Machine learning workspace private link endpoint name')
param p_machineLearningPleName string

@description('Resource ID of the virtual network resource')
param p_virtualNetworkId string

@description('Resource ID of the subnet resource')
param p_subnetId string

@description('Resource ID of the machine learning workspace')
param p_workspaceArmId string

@description('Tags to add to the resources')
param tags object

var privateDnsZoneName =  {
  azureusgovernment: 'privatelink.api.ml.azure.us'
  azurecloud: 'privatelink.api.azureml.ms'
}

var privateAznbDnsZoneName = {
    azureusgovernment: 'privatelink.notebooks.usgovcloudapi.net'
    azurecloud: 'privatelink.notebooks.azure.net'
}

resource machineLearningPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: p_machineLearningPleName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: p_machineLearningPleName
        properties: {
          groupIds: [
            'amlworkspace'
          ]
          privateLinkServiceId: p_workspaceArmId
        }
      }
    ]
    subnet: {
      id: p_subnetId
    }
  }
}

resource amlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName[toLower(environment().name)]
  location: 'global'
}

resource amlPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${amlPrivateDnsZone.name}/${uniqueString(p_workspaceArmId)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_virtualNetworkId
    }
  }
}

resource notebookPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateAznbDnsZoneName[toLower(environment().name)]
  location: 'global'
}

resource notebookPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${notebookPrivateDnsZone.name}/${uniqueString(p_workspaceArmId)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_virtualNetworkId
    }
  }
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${machineLearningPrivateEndpoint.name}/amlworkspace-PrivateDnsZoneGroup'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneName[environment().name]
        properties:{
          privateDnsZoneId: amlPrivateDnsZone.id
        }
      }
      {
        name: privateAznbDnsZoneName[environment().name]
        properties:{
          privateDnsZoneId: notebookPrivateDnsZone.id
        }
      }
    ]
  }
}
