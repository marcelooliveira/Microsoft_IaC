targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'bicep-rg'
  location: 'eastus'
}

module vmAndPostgreSQLModule 'VMAndPostgreSQL.bicep' = {
  name: 'VMAndPostgreSQL'
  scope: rg
}
