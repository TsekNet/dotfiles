@{
  PSDependOptions      = @{
    Target = 'CurrentUser'
    Import = $true
  }
  PowerShellGet        = 'latest'
  'Get-ChildItemColor' = @{
    DependsOn = 'PowerShellGet'
  }
  PSWriteHTML          = @{
    DependsOn = 'PowerShellGet'
  }
  PSReadLine           = @{
    DependsOn  = 'PowerShellGet'
    Install    = $false
    Parameters = @{
      AllowPrerelease = $true
    }
  }
}