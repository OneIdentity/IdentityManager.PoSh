function Get-Authentifier {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'Connectionstring to an Identity Manager database')]
    [ValidateNotNullOrEmpty()]
    [String] $ConnectionString,
    [Parameter(Mandatory = $false, HelpMessage = 'The connection factory to use. This parameter is obsolete.')]
    [ValidateSet('VI.DB.ViSqlFactory', 'VI.DB.Oracle.ViOracleFactory', 'QBM.AppServer.Client.ServiceClientFactory')]
    [String] $FactoryName = 'VI.DB.ViSqlFactory',
    [parameter(Mandatory = $false, HelpMessage = 'The base path to load the Identity Manager product files from.')]
    [string] $ProductFilePath = $null,
    [Parameter(Mandatory = $false, HelpMessage = 'The product to query for authentication methods')]
    [ValidateSet('API Designer', 'Application Server', 'Default', 'Designer', 'LaunchPad', 'Manager', 'OperationsSupportWebPortal', 'PasswordReset', 'SOAP Service', 'SPML Service', 'WebDesigner', 'WebDesignerEditor')]
    [String] $Product = 'Manager'
  )
  
  Begin {
    # make sure our exception handler function is loaded
    if (-not (Get-Command 'Resolve-Exception' -errorAction SilentlyContinue)) {
      . (Join-Path "$PSScriptRoot".Replace('Public', 'Private') 'common.ps1')
    }

    # Load product files
    $oneImBasePath = Add-IdentityManagerProductFile "$ProductFilePath"
  }

  Process {
    try {

      $FactoryName = Get-SqlFactoryFromConnectionString $ConnectionString

      if ($FactoryName -eq 'QBM.AppServer.Client.ServiceClientFactory') {
        [System.AppDomain]::CurrentDomain.add_AssemblyResolve($Global:OnAssemblyResolve)
        [System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, 'QBM.AppServer.Client.dll')) | Out-Null
      }

      $factory = New-Object -TypeName $FactoryName

      # We have to deregister the event handler here otherwise the powershell get's a stackoverflow
      [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($Global:OnAssemblyResolve)

      $sessionfactory = [VI.DB.DbApp]::ConnectTo($ConnectionString).Using($factory).BuildSessionFactory()

      $resolve = $sessionfactory.CommonServices.GetType().GetMethod('Resolve')
      $authmoduleInfoSourceInterface = $resolve.MakeGenericMethod([VI.DB.Auth.IAuthModuleInfoSource])
      $authmoduleInfoSource = $authmoduleInfoSourceInterface.Invoke($sessionfactory.CommonServices, @())
      $modules = $authmoduleInfoSource.GetUIAuthentifiersAsync($Product, $noneToken).GetAwaiter().GetResult() | Select-Object Caption, Ident

      Write-Output $modules

      if ($null -ne $sessionfactory) {
        $sessionfactory.Dispose()
      }
    }
    catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}

