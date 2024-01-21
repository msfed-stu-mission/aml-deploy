@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Name of the managed identity')
param p_managedIdentityName string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-PREVIEW' = {
  name: p_managedIdentityName
  location: location
  tags: tags
}

output managedIdentityName string = identity.name
output managedIdentityId string = identity.id
