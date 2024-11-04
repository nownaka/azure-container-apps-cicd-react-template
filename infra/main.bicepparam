using './main.bicep'

// The resources are named as shown below.
// {resourceAbbreviation}-{appName}-{suffix}
// Check: https://learn.microsoft.com/ja-jp/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

param appName = '{your app name}' // require
param environment = '{your environment name}' // require
param suffix = '' // option

param federatedIdentityCredentialsConfig = { // require
  name: 'github_federation_for_azure_container_services'
  audiendes: ['api://AzureADTokenExchange']
  issuer: 'https://token.actions.githubusercontent.com'
  subjedt: 'repo:{github account name}/{github repository name}:environment:{environment name}'
}

// About federatedIdentityCredentialsConfig
// For github, it must be in the following format.
//  - name:
//    The federated identity credential name must contain only letters (A-Z, a-z), numbers, hyphens, and dashes. Must begin with a number or letter.
//    The name of a federated identity credentials must be within 3 and 120 characters, only contains letters (A-Z, a-z), numbers, hyphens and dashes and must start with a number or letter.
//  - adudiendes:
//    Must be ['api://AzureADTokenExchange'].
//  - issuer:
//    Must be 'https://token.actions.githubusercontent.com'.
//  - subjedt:
//    repo:{github account name}/{github repository name}:{entity}
//    - entity:
//        Environment => environment:{environment name} <<<= **** 
//        Branch => ref:refs/heads/{branch name}
