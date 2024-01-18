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

@description('Resource ID of the Azure Kubernetes services resource')
param p_amlComputePublicIp bool

@description('VM size for the default compute cluster')
param p_vmSizeParam string

resource amlComputeCluster 'Microsoft.MachineLearningServices/workspaces/computes@2022-05-01' = {
  name: '${p_machineLearningWorkspaceName}/${p_prefix}-cluster${p_version}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    computeType: 'AmlCompute'
    computeLocation: location
    description: 'Machine Learning cluster ${p_version}'
    disableLocalAuth: true
    properties: {
      vmPriority: 'Dedicated'
      vmSize: p_vmSizeParam
      enableNodePublicIp: p_amlComputePublicIp
      isolatedNetwork: false
      osType: 'Linux'
      remoteLoginPortPublicAccess: 'Disabled'
      scaleSettings: {
        minNodeCount: 0
        maxNodeCount: 5
        nodeIdleTimeBeforeScaleDown: 'PT120S'
      }
      subnet: {
        id: p_computeSubnetId
      }
    }
  }
}

output clusterName string = amlComputeCluster.name
