@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Application Insights resource name')
param p_applicationInsightsName string

@description('Log Analytics resource name')
param p_logAnalyticsWorkspaceName string 

@description('Name of the user-managed identity')
param p_managedIdentityName string 

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: p_logAnalyticsWorkspaceName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${p_managedIdentityName}': {}
    }
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    forceCmkForQuery: true
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: p_applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    Flow_Type: 'Bluefield'
  }
}

output applicationInsightsId string = applicationInsights.id
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
