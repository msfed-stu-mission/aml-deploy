@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Name of the storage account')
param p_storageName string

@description('Name of the storage blob private link endpoint')
param p_storagePleBlobName string

@description('Name of the storage file private link endpoint')
param p_storagePleFileName string

@description('Resource ID of the subnet')
param p_subnetId string

@description('Managed identity name')
param p_managedIdentityName string 

@description('Key Vault name')
param p_keyVaultName string 

@description('CMK name for storage key')
param p_cmkKeyName string

@description('Resource ID of the virtual network')
param p_virtualNetworkId string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])

@description('Storage SKU')
param storageSkuName string = 'Standard_LRS'

var storageNameCleaned = replace(p_storageName, '-', '')

var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'

var filePrivateDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'

resource identity 'Microsoft.ManagedIdentity/identities@2023-07-31-preview' existing = {
  name: p_managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: p_keyVaultName
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageNameCleaned
  location: location
  tags: tags
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: p_cmkKeyName
        keyvaulturi: keyVault.properties.vaultUri
      }
      requireInfrastructureEncryption: true
      identity: {
        // specify which identity to use
        userAssignedIdentity: identity.id
      }
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource storagePrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: p_storagePleBlobName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      { 
        name: p_storagePleBlobName
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storage.id
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

resource storagePrivateEndpointFile 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: p_storagePleFileName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: p_storagePleFileName
        properties: {
          groupIds: [
            'file'
          ]
          privateLinkServiceId: storage.id
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

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${storagePrivateEndpointBlob.name}/blob-PrivateDnsZoneGroup'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: blobPrivateDnsZoneName
        properties:{
          privateDnsZoneId: blobPrivateDnsZone.id
        }
      }
    ]
  }
}

resource blobPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateDnsZone.name}/${uniqueString(storage.id)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_virtualNetworkId
    }
  }
}

resource filePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: filePrivateDnsZoneName
  location: 'global'
}

resource filePrivateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${storagePrivateEndpointFile.name}/flie-PrivateDnsZoneGroup'
  properties:{
    privateDnsZoneConfigs: [
      {
        name: filePrivateDnsZoneName
        properties:{
          privateDnsZoneId: filePrivateDnsZone.id
        }
      }
    ]
  }
}

resource filePrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${filePrivateDnsZone.name}/${uniqueString(storage.id)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: p_virtualNetworkId
    }
  }
}

output storageId string = storage.id
