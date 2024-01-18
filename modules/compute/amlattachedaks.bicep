@description('Name of the Azure Kubernetes Service cluster')
param p_aksClusterName string

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Resource ID for the Azure Kubernetes Service subnet')
param p_aksSubnetId string

@description('Azure Machine Learning workspace in which to create the compute resource')
param p_machineLearningWorkspaceName string

@description('Name of the Azure Machine Learning attached compute')
param p_computeName string

@description('Size of the virtual machine pool')
param p_vmSizeParam string 

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-04-01' = {
  name: p_aksClusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.27.1'
    dnsPrefix: '${p_aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: toLower('agentpool')
        count: 3
        vmSize: p_vmSizeParam
        osDiskSizeGB: 128
        vnetSubnetID: p_aksSubnetId
        maxPods: 110
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]
    enableRBAC: true
    networkProfile: {
      networkPlugin: 'kubenet'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      loadBalancerSku: 'standard'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
  }
}

resource reparentAttachedCompute 'Microsoft.MachineLearningServices/workspaces/computes@2022-05-01' = {
  name: '${p_machineLearningWorkspaceName}/${p_computeName}'
  location: location
  properties: {
    computeType: 'AKS'
    resourceId: aksCluster.id
    properties: {
      aksNetworkingConfiguration:  {
        subnetId: p_aksSubnetId
      }
    }
  }
}

output aksResourceId string = aksCluster.id
