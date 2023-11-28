function New-IdentityManagerSession {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, HelpMessage = 'Connectionstring to an Identity Manager database')]
    [ValidateNotNullOrEmpty()]
    [String] $ConnectionString,
    [parameter(Mandatory = $true, HelpMessage = 'The authentication to use')]
    [ValidateNotNullOrEmpty()]
    [String] $AuthenticationString,
    [Parameter(Mandatory = $false, HelpMessage = 'The connection factory to use')]
    [ValidateSet('VI.DB.ViSqlFactory', 'VI.DB.Oracle.ViOracleFactory', 'QBM.AppServer.Client.ServiceClientFactory')]
    [String] $FactoryName = 'VI.DB.ViSqlFactory',
    [parameter(Mandatory = $false, HelpMessage = 'The base path to load the Identity Manager product files from.')]
    [string] $ProductFilePath,
    [Parameter(Mandatory = $false, HelpMessage = 'Cmdlet prefix to use for handling multiple connections')]
    [String] $Prefix = '',
    [Parameter(Mandatory = $false, HelpMessage = 'List of modules to skip for function generation')]
    [String[]] $ModulesToSkip,
    [Parameter(Mandatory = $false, HelpMessage = 'List of modules to add for function generation')]
    [String[]] $ModulesToAdd,
    [Parameter(Mandatory = $false, HelpMessage = 'If the switch is specified the type wrapper functions will not be created (e.g. New-Person, New-ADSAccount)')]
    [switch] $SkipFunctionGeneration = $false
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
      # Check if there is already a session in global session store with this prefix
      if ($Global:imsessions.Contains($Prefix)) {
        throw "There is already a connection with prefix '$Prefix' defined. Please specify another prefix."
      }

      if ($FactoryName -eq 'QBM.AppServer.Client.ServiceClientFactory') {
        [System.AppDomain]::CurrentDomain.add_AssemblyResolve($Global:OnAssemblyResolve)
        [System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, 'QBM.AppServer.Client.dll')) | Out-Null
      }

      # Create the session
      $factory = New-Object -TypeName $FactoryName

      # We have to deregister the event handler here otherwise the powershell get's a stackoverflow
      [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($Global:OnAssemblyResolve)

      $sessionfactory = [VI.DB.DbApp]::ConnectTo($ConnectionString).Using($factory).BuildSessionFactory()
      $session = [VI.DB.Sync.SyncSessionFactoryExtensions]::Open($sessionfactory, $AuthenticationString)

      # Add session to global session store
      $Global:imsessions.Add($Prefix, @{ Factory = $sessionfactory; Session = $session })

      # Generate typed wrapper functions if SkipFunctionGeneration switch is not specified
      if (-not $SkipFunctionGeneration) {
        if (-not $Global:newTypedWrapperProviderDone) {
          New-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip -ModulesToAdd $ModulesToAdd
        }
        if (-not $Global:getTypedWrapperProviderDone) {
          Get-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip -ModulesToAdd $ModulesToAdd
        }
        if (-not $Global:removeTypedWrapperProviderDone) {
          Remove-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip -ModulesToAdd $ModulesToAdd
        }
        if (-not $Global:setTypedWrapperProviderDone) {
          Set-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip -ModulesToAdd $ModulesToAdd
        }
      }

      $session
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}