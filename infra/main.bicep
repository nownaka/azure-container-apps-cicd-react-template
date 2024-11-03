//
// Bicep template to create Container Apps on Azure.
//

// --------------------------------------------------------------------------------
// Params
// --------------------------------------------------------------------------------
@description('Resource deployment region.')
param location string = resourceGroup().location

@description('Application name.')
param appName string
@description('Environment name.')
param environment string
param suffix string = ''
@description('Base name of the resource. Used if there is no specification for each resource name.')
param resourceBaseName string = join(split(join([appName, environment, suffix], '-'), '-'), '-')

@description('Resource name of Log Analytics Workspace.')
param workspaceName string = 'log-${resourceBaseName}'
@description('Resource name of Azure Container Registry.')
param resistoryName string = 'cr${replace(resourceBaseName, '-', '')}'
@description('Resource name of Azure Container Apps Environment.')
param containerAppsEnvironmentName string = 'cae-${resourceBaseName}'
@description('Resource name of User Assigned Managed Identity.')
param userAssignedIdentityName string = 'id-${resourceBaseName}'
@description('Resource name of Azure Container Apps.')
param containerAppName string = 'ca-${resourceBaseName}'

@description('Role definition to assign.')
param roleDifinitions { name: string, id: string }[] = [
  {
    name: 'acrPull'
    id: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
]

// --------------------------------------------------------------------------------
// Resources
// --------------------------------------------------------------------------------

/* Log Analytics Workspace */
@description('Log Analytics Workspace')
module logAnalyticsworkspace './modules/workspaces.bicep' = {
  name: 'Deploy-LogAnalyticsWorkspace'
  params: {
    workspaceLocation: location
    workspaceName: workspaceName
  }
}

/* Azure Container Registry */
@description('Azure Container Registry')
module containerRegistry './modules/registries.bicep' = {
  name: 'Deploy-ContainerRegistory'
  params: {
    registryLocation: location
    registryName: resistoryName
  }
}

/* Azure Container Apps Environment */
@description('Azure Container Apps Environment')
module containerAppsEnvironment './modules/environment.bicep' = {
  name: 'Deploy-ContainerAppsEnvironment'
  params: {
    environmentLocation: location
    environmentName: containerAppsEnvironmentName
    workspaceName: logAnalyticsworkspace.outputs.workspaceName
  }
}

/* User Assigned Managed Identity */
@description('User Assigned Managed Identity')
module userAssignedIdentity './modules/userAssignedIdentities.bicep' = {
  name: 'Deploy-UserAssignedIdentity'
  params: {
    userAssignedIdentityName: userAssignedIdentityName
    userAssignedIdentityLocation: location
  }
}



/* Role Assingnment */
@description('Role Assingnment')
module roleAssignment './modules/roleAssignmentsFromARM.bicep' = [ for roleDifinition in roleDifinitions: {
  name: 'RoleAssignement-${roleDifinition.name}'
  params: {
    roleName: roleDifinition.name
    roleDefinitionId: roleDifinition.id
    principalId: userAssignedIdentity.outputs.principalId
    resourceId: containerRegistry.outputs.resourceId
  }
}]

/* Azure Container Apps */
var _managedIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: { '${userAssignedIdentity.outputs.resourceId}' : {}}
}
var _registryServer = containerRegistry.outputs.loginServer
var _resistories = [
  {
    identity: userAssignedIdentity.outputs.resourceId
    server: _registryServer
}]

@description('Azure Container App')
module containerApp './modules/containerapps.bicep' = {
  name: 'Deploy-ContainerApp'
  params: {
    containerappLocation: location
    containerappName: containerAppName
    environmentId: containerAppsEnvironment.outputs.resourceId
    registryServer: _registryServer
    managedIdentity: _managedIdentity
    registries: _resistories
  }
}

// --------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------
@description('The Client App Id of User Assigned Managed Identity.')
output AZURE_CLIENT_ID string = userAssignedIdentity.outputs.clientId
@description('The Tenant Id.')
output AZURE_TENANT_ID string = tenant().tenantId
@description('The Subscription Id.')
output AZURE_SUBSCRIPTION_ID string = subscription().id
@description('The Resouce Group name.')
output AZURE_RESOURCE_GROUP_NAME string = resourceGroup().name
