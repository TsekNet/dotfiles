@{
  PSDependOptions      = @{
    Target = 'CurrentUser'
    Import = $false
  }
  PowerShellGet        = @{
    Version = '2.2.5'
    Parameters = @{
      AllowClobber = $true
    }
  }
  'Get-ChildItemColor' = @{
    DependsOn = 'PowerShellGet'
    Parameters = @{
      AllowClobber = $true
    }
  }
  PSWriteHTML          = @{
    DependsOn = 'PowerShellGet'
    Parameters = @{
      AllowClobber = $true
    }
  }
  PSReadLine           = @{
    DependsOn  = 'PowerShellGet'
    Parameters = @{
      AllowPrerelease = $true
      AllowClobber = $true
    }
  }
}
