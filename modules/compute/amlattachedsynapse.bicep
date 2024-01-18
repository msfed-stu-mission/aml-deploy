@description('Prefix for resource names')
param p_prefix string

@description('Compute version')
param p_version string

@description('Azure Machine Learning workspace in which to create the compute resource')
param p_machineLearningWorkspaceName string

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('How many nodes to use in the Spark pool (min: 3)')
@minValue(3)
param p_nodeCount int 

@description('Enable autoscale on the Spark pool')
param p_enableAutoScale bool = true

@description('Maximum value for node autoscaling')
param p_maxNodeCount int

@description('Minimum value for node autoscaling')
param p_minNodeCount int

@description('Enable auto-pausing on the Spark pool (recommended, defaults to true)')
param p_enableAutoPause bool = true

@description('The auto-pause delay in minutes')
param p_autoPauseDelayMins int = 15 

@description('The Spark node family')
@allowed([
  'HardwareAcceleratedFPGA'
  'HardwareAcceleratedGPU'
  'MemoryOptimized'
])
param p_nodeFamily string = 'MemoryOptimized'

@description('The Spark node size')
@allowed([
  'Large'
  'Medium'
  'None'
  'Small'
  'XLarge'
  'XXLarge'
  'XXXLarge'
])
param p_nodeSize string = 'Large'

@description('Name of the Spark pool')
param p_sparkPoolName string 

@description('Name of the corresponding Synapse workspace')
param p_synapseWorkspaceName string 

@description('The version of Apache Spark')
param p_sparkVersion string 

var v_poolNameCleaned = replace(p_sparkPoolName, '-', '')

resource amlLinkedSparkPool 'Microsoft.MachineLearningServices/workspaces/computes@2022-05-01' = {
  name: '${p_machineLearningWorkspaceName}/${p_prefix}-sparkpool${p_version}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    computeType: 'SynapseSpark'
    computeLocation: location
    description: 'Machine Learning Spark pool ${p_version}'
    disableLocalAuth: true
    properties: {
      autoPauseProperties: {
        delayInMinutes: p_autoPauseDelayMins
        enabled: p_enableAutoPause
      }
      autoScaleProperties: {
        enabled: p_enableAutoScale
        maxNodeCount: p_maxNodeCount
        minNodeCount: p_minNodeCount
      }
      nodeCount: p_nodeCount
      nodeSize: p_nodeSize
      nodeSizeFamily: p_nodeFamily
      poolName: v_poolNameCleaned
      resourceGroup: resourceGroup().name
      sparkVersion: p_sparkVersion
      subscriptionId: subscription().id
      workspaceName: p_synapseWorkspaceName
    }
  }
}

output linkedPoolComputeName string = amlLinkedSparkPool.name
