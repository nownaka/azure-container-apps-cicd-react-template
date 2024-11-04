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
param registryName string = 'cr${replace(resourceBaseName, '-', '')}'
@description('Resource name of Azure Container Apps Environment.')
param containerAppsEnvironmentName string = 'cae-${resourceBaseName}'
@description('Resource name of User Assigned Managed Identity.')
param userAssignedIdentityName string = 'id-${resourceBaseName}'
@description('Resource name of Azure Container Apps.')
param containerAppName string = 'ca-${resourceBaseName}'

@description('')
param federatedIdentityCredentialsConfig { name: string, audiendes: string[], issuer: string, subjedt: string }

@description('Role definition to assign.')
param roleDifinitions { name: string, id: string }[] = [
  {
    name: 'AcrPull'
    id: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
  }
  {
    name: 'AcrPush'
    id: '8311e382-0749-4cb8-b61a-304f252e45ec'
  }
  {
    name: 'ContainerAppsContributor'
    id: '358470bc-b998-42bd-ab17-a7e34c199c0f'
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
  name: 'Deploy-ContainerRegistry'
  params: {
    registryLocation: location
    registryName: registryName
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

@description('Federated Identity Credentials.')
module federatedIdentityCredentials './modules/federatedIdentityCredentials.bicep' = {
  name: 'Add-FederatedIdentityCredentials'
  params: {
    federatedIdentityCredentialName: federatedIdentityCredentialsConfig.name
    userAssignedIdentityName: userAssignedIdentity.outputs.name
    audiendes: federatedIdentityCredentialsConfig.audiendes
    issuer: federatedIdentityCredentialsConfig.issuer
    subjedt: federatedIdentityCredentialsConfig.subjedt
  }
}

/* Role Assingnment */
@description('Role Assingnment')
module roleAssignment_containerRegistry './modules/roleAssignmentsFromARM.bicep' = [ for (roleDifinition , index) in roleDifinitions: if( index <= 1){
  name: 'RoleAssignement-${roleDifinition.name}'
  params: {
    roleName: roleDifinition.name
    roleDefinitionId: roleDifinition.id
    principalId: userAssignedIdentity.outputs.principalId
    resourceId: containerRegistry.outputs.resourceId
  }
}]

module roleAssignment_containerApp './modules/roleAssignmentsFromARM.bicep' = {
  name: 'RoleAssignement-${roleDifinitions[2].name}'
  params: {
    roleName: roleDifinitions[2].name
    roleDefinitionId: roleDifinitions[2].id
    principalId: userAssignedIdentity.outputs.principalId
    resourceId: containerApp.outputs.resourceId
  }
}

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
var _ingress = {
  external: true
  targetPort: 3000
}

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
    ingress: _ingress
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
@description('Domain name of Azure Container Registry.')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
@description('Resource name of Azure Container App.')
output AZURE_CONTAINER_APP_NAME string = containerApp.outputs.name
