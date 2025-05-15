@{
  ssoConnectionDetails = @{
    roleName    = 'ClientABC-FinOpsRole'
    sessionName = 'Client ABC Tagging Session'
    startUrl    = 'https://clientabc.awsapps.com/start/#/'
    ssoRegion   = 'eu-west-1'
  }

  accounts             = @(
    @{
      name        = "Client ABC - Prod"
      accountId   = "111111111111"
      profileName = "sso-client-abc-prod"
      regions     = @(
        "us-east-1"
        "eu-central-1"
      )
    }
    @{
      name        = "Client ABC - Non-Prod"
      accountId   = "222222222222"
      profileName = "sso-client-abc-nonprod"
      regions     = @(
        "eu-west-1"
      )
    }
  )

  requiredTagKeys      = @(
    "Environment"
    "CostCenter"
    "Sox"
    "ApplicationName"
    "Name"
  )
}