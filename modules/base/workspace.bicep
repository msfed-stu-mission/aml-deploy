@description('Prefix for resource names')
param prefix string

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Machine learning workspace name')
param p_machineLearningName string

@description('Machine learning workspace display name')
param machineLearningFriendlyName string = p_machineLearningName

@description('Machine learning workspace description')
param p_machineLearningDescription string

@description('Name of the Azure Kubernetes services resource to create and attached to the machine learning workspace')
param p_mlAksName string

@description('Resource ID of the application insights resource')
param p_applicationInsightsId string

@description('Resource ID of the container registry resource')
param p_containerRegistryId string

@description('Resource ID of the key vault resource')
param p_keyVaultId string

@description('Resource ID of the storage account resource')
param p_storageAccountId string

@description('Resource ID of the subnet resource')
param p_subnetId string

@description('Resource ID of the compute subnet')
param p_computeSubnetId string

@description('Resource ID of the Azure Kubernetes services resource')
param p_aksSubnetId string

@description('Resource ID of the virtual network')
param p_virtualNetworkId string

@description('Machine learning workspace private link endpoint name')
param p_machineLearningPleName string

@description('Enable public IP for Azure Machine Learning compute nodes')
param p_amlComputePublicIp bool = true

@description('VM size for the default compute cluster')
param p_vmSizeParam string
 
resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2022-05-01' = {
  name: p_machineLearningName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // workspace organization
    friendlyName: machineLearningFriendlyName
    description: p_machineLearningDescription

    // dependent resources
    applicationInsights: p_applicationInsightsId
    containerRegistry: p_containerRegistryId
    keyVault: p_keyVaultId
    storageAccount: p_storageAccountId

    // configuration for workspaces with private link endpoint
    imageBuildCompute: 'cluster001'
    publicNetworkAccess: 'Disabled'
  }
}

module machineLearningPrivateEndpoint '../network/amlendpoints.bicep' = {
  name: 'machineLearningNetworking'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    p_virtualNetworkId: p_virtualNetworkId
    p_workspaceArmId: machineLearning.id
    p_subnetId: p_subnetId
    p_machineLearningPleName: p_machineLearningPleName
  }
}

/**
module machineLearningCompute '../compute/amlcompute.bicep' = {
  name: 'machineLearningComputes'
  scope: resourceGroup()
  params: {
    p_machineLearningWorkspaceName: p_machineLearningName
    location: location
    p_computeSubnetId: p_computeSubnetId
    p_prefix: prefix
    tags: tags
    p_amlComputePublicIp: p_amlComputePublicIp
    p_vmSizeParam: p_vmSizeParam
    p_version: '001'
  }
  dependsOn: [
    machineLearning
    machineLearningPrivateEndpoint
  ]
}
*/
output machineLearningId string = machineLearning.id
