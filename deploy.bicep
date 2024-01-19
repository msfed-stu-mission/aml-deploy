@minLength(2)
@maxLength(10)
@description('Prefix for all resource names.')
param prefix string

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Virtual network address prefix')
param p_vnetAddressPrefix string = '192.168.0.0/16'

@description('Training subnet address prefix')
param p_trainingSubnetPrefix string = '192.168.0.0/24'

@description('Scoring subnet address prefix')
param p_scoringSubnetPrefix string = '192.168.1.0/24'

@description('Bastion subnet address prefix')
param p_azureBastionSubnetPrefix string = '192.168.250.0/27'

@description('Deploy a Bastion jumphost to access the network-isolated environment?')
param p_deployJumphost bool = true

@description('Jumphost virtual machine username')
param p_dsvmJumpboxUsername string

@secure()
@minLength(8)
@description('Jumphost virtual machine password')
param p_dsvmJumpboxPassword string

@description('Enable public IP for Azure Machine Learning compute nodes')
param p_amlComputePublicIp bool = true

@description('VM size for the default compute cluster')
param p_amlComputeDefaultVmSize string = 'Standard_DS3_v2'

@description('Name of the training subnet for cluster access')
param p_trainingSubnetName string = 'SNET-Train'

@description('Name of the scoring subnet for inference endpoints')
param p_scoringSubnetName string = 'SNET-Score'

// Variables
var v_name = toLower('${prefix}')

// Create a short, unique suffix, that will be unique to each resource group
var v_uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)

// Virtual network and network security group
module nsg 'modules/network/nsg.bicep' = { 
  name: 'nsg-${v_name}-${v_uniqueSuffix}-deployment'
  params: {
    location: location
    tags: tags 
    p_nsgName: 'nsg-${v_name}-${v_uniqueSuffix}'
  }
}

module vnet 'modules/network/vnet.bicep' = { 
  name: 'vnet-${v_name}-${v_uniqueSuffix}-deployment'
  params: {
    location: location
    p_virtualNetworkName: 'vnet-${v_name}-${v_uniqueSuffix}'
    p_networkSecurityGroupId: nsg.outputs.networkSecurityGroup
    p_vnetAddressPrefix: p_vnetAddressPrefix
    p_trainingSubnetPrefix: p_trainingSubnetPrefix
    p_scoringSubnetPrefix: p_scoringSubnetPrefix
    tags: tags
  }
}

// Dependent resources for the Azure Machine Learning workspace
module keyvault 'modules/base/vault.bicep' = {
  name: 'kv-${v_name}-${v_uniqueSuffix}-deployment'
  params: {
    location: location
    p_keyvaultName: 'kv-${v_name}-${v_uniqueSuffix}'
    p_keyvaultPleName: 'ple-${v_name}-${v_uniqueSuffix}-kv'
    p_subnetId: '${vnet.outputs.id}/subnets/${p_trainingSubnetName}'
    p_virtualNetworkId: vnet.outputs.id
    tags: tags
  }
}

module storage 'modules/base/storage.bicep' = {
  name: 'st${v_name}${v_uniqueSuffix}-deployment'
  params: {
    location: location
    p_storageName: 'st${v_name}${v_uniqueSuffix}'
    p_storagePleBlobName: 'ple-${v_name}-${v_uniqueSuffix}-st-blob'
    p_storagePleFileName: 'ple-${v_name}-${v_uniqueSuffix}-st-file'
    storageSkuName: 'Standard_LRS'
    p_subnetId: '${vnet.outputs.id}/subnets/${p_trainingSubnetName}'
    p_virtualNetworkId: vnet.outputs.id
    tags: tags
  }
}

module containerRegistry 'modules/base/acr.bicep' = {
  name: 'cr${v_name}${v_uniqueSuffix}-deployment'
  params: {
    location: location
    p_containerRegistryName: 'cr${v_name}${v_uniqueSuffix}'
    p_containerRegistryPleName: 'ple-${v_name}-${v_uniqueSuffix}-cr'
    p_subnetId: '${vnet.outputs.id}/subnets/${p_trainingSubnetName}'
    p_virtualNetworkId: vnet.outputs.id
    tags: tags
  }
}

module applicationInsights 'modules/applicationinsights.bicep' = {
  name: 'appi-${p_name}-${p_uniqueSuffix}-deployment'
  params: {
    location: p_location
    applicationInsightsName: 'appi-${p_name}-${p_uniqueSuffix}'
    logAnalyticsWorkspaceName: 'ws-${p_name}-${p_uniqueSuffix}'
    tags: p_tags
  }
}

module azuremlWorkspace 'modules/base/workspace.bicep' = {
  name: 'mlw-${p_name}-${p_uniqueSuffix}-deployment'
  params: {
    // workspace organization
    machineLearningName: 'mlw-${p_name}-${p_uniqueSuffix}'
    machineLearningFriendlyName: 'Private link endpoint sample workspace'
    machineLearningDescription: 'This is an example workspace having a private link endpoint.'
    location: p_location
    prefix: p_name
    tags: p_tags

    // dependent resources
    applicationInsightsId: applicationInsights.outputs.applicationInsightsId
    containerRegistryId: containerRegistry.outputs.containerRegistryId
    keyVaultId: keyvault.outputs.keyvaultId
    storageAccountId: storage.outputs.storageId

    // networking
    subnetId: '${vnet.outputs.id}/subnets/${p_trainingSubnetName}'
    computeSubnetId: '${vnet.outputs.id}/subnets/${p_trainingSubnetName}'
    aksSubnetId: '${vnet.outputs.id}/subnets/${p_scoringSubnetName}'
    virtualNetworkId: vnet.outputs.id
    machineLearningPleName: 'ple-${p_name}-${p_uniqueSuffix}-mlw'

    // compute
    amlComputePublicIp: p_amlComputePublicIp
    mlAksName: 'aks-${p_name}-${p_uniqueSuffix}'
    vmSizeParam: p_amlComputeDefaultVmSize
  }
  dependsOn: [
    keyvault
    containerRegistry
    applicationInsights
    storage
  ]
}
