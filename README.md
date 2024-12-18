# Secure Azure Machine Learning Deployment Accelerator

![Bicep Version](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.machinelearningservices/machine-learning-end-to-end-secure/BicepVersion.svg)

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.machinelearningservices%2Fmachine-learning-end-to-end-secure%2Fazuredeploy.json)
[![Deploy To Azure US Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.machinelearningservices%2Fmachine-learning-end-to-end-secure%2Fazuredeploy.json)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.machinelearningservices%2Fmachine-learning-end-to-end-secure%2Fazuredeploy.json)

The Secure Azure Machine Learning Accelerator provides an out-of-the-box secure deployment of Azure Machine Learning, along with auxiliary resources required for a production-grade workspace instantiation.

This reference implementation includes features such as network isolation, customer-managed key setup, auto-cluster provisioning, and optionally attaching to separate AKS clusters or Synapse Spark Pools.

## Getting Started

### Prerequisites

These template scripts will deploy several resources into your Azure environment. Prior to attempting deployment, certain pre-reqs must be completed. Please ensure these items are done before continuing on to the deployment section of this guide:

To get started with deployment, you will need the following:

>- An active Azure Subscription - e.g., Azure commercial, Azure US Gov
>- Administrative rights on the Azure Subscription
>- An existing resource group in which to deploy the Azure ML workspace & resources
>- Contributer and Key Vault Administrator roles at the resource group level

You can sign up for an Azure subscription [here](https://azure.microsoft.com/en-us/free/)

### Securely Deploying Azure ML

The Secure Azure Machine Learning Accelerator can be deployed to Azure or Azure US Gov using the single-click deployment buttons at the top of this page. These will automatically deploy an network-isolated Azure ML workspace and configure all features.

Alternatively, this repository may be cloned and modified if desired. The `deploy.bicep` template at the root directory of this accelerator is intended to be an example arrangement of the underlying bicep modules found in the `modules` directory. These modules are designed to be reusable and may be arranged as needed.

## Resources

| Provider and type | Description |
| - | - |
| `Microsoft.Resources/resourceGroups` | The resource group all resources get deployed into |
| `Microsoft.Insights/components` | An Azure Application Insights instance associated to the Azure Machine Learning workspace |
| `Microsoft.KeyVault/vaults` | An Azure Key Vault instance associated to the Azure Machine Learning workspace |
| `Microsoft.Storage/storageAccounts` | An Azure Storage instance associated to the Azure Machine Learning workspace |
| `Microsoft.ContainerRegistry/registries` | An Azure Container Registry instance associated to the Azure Machine Learning workspace |
| `Microsoft.MachineLearningServices/workspaces` | An Azure Machine Learning workspace instance |
| `Microsoft.MachineLearningServices workspaces/computes` | Azure Machine Learning workspace compute types: cluster and compute instance |
| `Microsoft.Network/privateDnsZones` | Private DNS zones for Azure Machine Learning and the dependent resources |
| `Microsoft.Network/networkSecurityGroups` | A Network Security Group pre-configured for use with Azure Machine Learning |
| `Microsoft.ContainerService/managedClusters` | An Azure Kubernetes Services cluster for inferencing |
| `Microsoft.Network/virtualNetworks` | A virtual network to deploy all resources in |

## Learn more

If you are new to Azure Machine Learning, see:

- [Azure Machine Learning service](https://azure.microsoft.com/services/machine-learning-service/)
- [Azure Machine Learning documentation](https://docs.microsoft.com/azure/machine-learning/)
- [Enterprise security and governance for Azure Machine Learning](https://docs.microsoft.com/azure/machine-learning/concept-enterprise-security).
- [Azure Machine Learning template reference](https://docs.microsoft.com/azure/templates/microsoft.machinelearningservices/allversions)

If you are new to template development, see:

- [Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
- [Use an Azure Resource Manager template to create a workspace for Azure Machine Learning](https://docs.microsoft.com/azure/machine-learning/service/how-to-create-workspace-template)
- [Quickstart templates](https://azure.microsoft.com/resources/templates/)
