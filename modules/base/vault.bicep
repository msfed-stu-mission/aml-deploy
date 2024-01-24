@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location

@description('Tags to apply to the Key Vault Instance')
param tags object = {}

@description('The name of the Key Vault')
param p_keyvaultName string

@description('The name of the Key Vault private link endpoint')
param p_keyvaultPleName string

@description('The Subnet ID where the Key Vault Private Link is to be created')
param p_subnetId string

@description('The VNet ID where the Key Vault Private Link is to be created')
param p_virtualNetworkId string

@description('Enable soft-delete')
param p_enableSoftDelete bool = false

@description('Managed identity name')
param p_managedIdentityName string

var privateDnsZoneName = 'privatelink${environment().suffixes.keyvaultDns}'

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: p_keyvaultName
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: p_enableSoftDelete
    enableRbacAuthorization: true
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: p_keyvaultPleName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: p_keyvaultPleName
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVault.id
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: p_subnetId
    }
  }
}

resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${keyVaultPrivateEndpoint.name}/vault-PrivateDnsZoneGroup'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneName
        properties:{
          privateDnsZoneId: keyVaultPrivateDnsZone.id
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${keyVaultPrivateDnsZone.name}/${uniqueString(keyVault.id)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_virtualNetworkId
    }
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-PREVIEW' existing = {
  name: p_managedIdentityName
}

resource keyVaultOfficerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('grant-vault-access', identity.id, keyVault.id)
  properties: {
    roleDefinitionId: keyVaultOfficerRoleDefinition.id
    principalId: identity.properties.principalId
  }
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: identity.properties.principalId
        permissions: {
          keys: [
            'get'
            'unwrapKey'
            'wrapKey'
          ]
        }
      }
    ]
  }
} 

var cmkKeyName = '${uniqueString(keyVault.id)}${uniqueString(subscription().id)}'
resource key 'Microsoft.KeyVault/vaults/keys@2021-06-01-preview' = {
  name: '${uniqueString(keyVault.id)}${cmkKeyName}'
  parent: keyVault
  properties: {
    keySize: 2048
    kty: 'RSA'
    keyOps: [
      'unwrapKey'
      'wrapKey'
    ]
  }
}

output keyvaultId string = keyVault.id
output keyvaultName string = keyVault.name
output cmkKeyName string = key.name
