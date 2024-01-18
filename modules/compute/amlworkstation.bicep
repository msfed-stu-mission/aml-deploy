@description('Prefix for resource names')
param p_prefix string

@description('Cluster version')
param p_version string

@description('Azure Machine Learning workspace in which to create the compute resource')
param p_machineLearningWorkspaceName string

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Resource ID of the compute subnet')
param p_computeSubnetId string

@description('VM size for the compute instance')
param p_vmSizeParam string

resource machineLearningComputeInstance001 'Microsoft.MachineLearningServices/workspaces/computes@2022-05-01' = {
  name: '${p_machineLearningWorkspaceName}/${p_prefix}-workstation-${p_version}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    computeType: 'ComputeInstance'
    computeLocation: location
    description: 'Machine Learning compute instance ${p_version}'
    disableLocalAuth: true
    properties: {
      applicationSharingPolicy: 'Personal'
      
      computeInstanceAuthorizationType: 'personal'
      sshSettings: {
        sshPublicAccess: 'Disabled'
      }
      subnet: {
        id: p_computeSubnetId
      }
      vmSize: p_vmSizeParam
    }
  }
}
