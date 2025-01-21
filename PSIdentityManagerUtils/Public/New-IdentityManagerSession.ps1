function New-IdentityManagerSession {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'Connectionstring to an Identity Manager database')]
    [ValidateNotNullOrEmpty()]
    [String] $ConnectionString,
    [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The authentication to use')]
    [ValidateNotNullOrEmpty()]
    [String] $AuthenticationString,
    [Parameter(Mandatory = $false, HelpMessage = 'The connection factory to use. This parameter is obsolete.')]
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
    [switch] $SkipFunctionGeneration = $false,
    [Parameter(Mandatory = $false, HelpMessage = 'If the switch is specified the trace mode for the Identity Manager will be activated. This means NLog will use log level trace.')]
    [switch] $TraceMode = $false
  )

  Begin {
    # make sure our exception handler function is loaded
    if (-not (Get-Command 'Resolve-Exception' -ErrorAction SilentlyContinue)) {
      . (Join-Path "$PSScriptRoot".Replace('Public', 'Private') -ChildPath 'common.ps1')
    }

    $oneImBasePath = Add-IdentityManagerProductFile "$ProductFilePath" -TraceMode:$TraceMode

    if ($TraceMode) {
      $traceFile = Join-Path $(New-TemporaryDirectory) 'PSIdentityManagerUtils_trace.log'
      [NLog.Config.SimpleConfigurator]::ConfigureForFileLogging($traceFile, [NLog.LogLevel]::FromString('Trace'))

      Write-Information "[!] TraceMode is active and log file will be written to '${traceFile}'."
    }
  }

  Process {

    try {
      # Check if there is already a session in global session store with this prefix
      if ($Global:imsessions.Contains($Prefix)) {
        throw "[!] There is already a connection with prefix '$Prefix' defined. Please specify another prefix."
      }

      $FactoryName = Get-SqlFactoryFromConnectionString $ConnectionString

      if ($FactoryName -eq 'QBM.AppServer.Client.ServiceClientFactory') {
        [System.AppDomain]::CurrentDomain.add_AssemblyResolve($Global:OnAssemblyResolve)
        Add-FileToAppDomain -BasePath $oneImBasePath -File 'QBM.AppServer.Client.dll' | Out-Null
      }

      # Create the session
      $factory = New-Object -TypeName $FactoryName

      # We have to deregister the event handler here otherwise the powershell get's a stackoverflow
      [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($Global:OnAssemblyResolve)

      $sessionfactory = [VI.DB.DbApp]::ConnectTo($ConnectionString).Using($factory).BuildSessionFactory()
      $session = [VI.DB.Sync.SyncSessionFactoryExtensions]::Open($sessionfactory, $AuthenticationString)

      # Add Factory as custom PowerShell property to session object
      try {
        if ($null -eq $session.PSObject.Members['Factory']) {
          $session | Add-Member -NotePropertyName 'Factory' -NotePropertyValue $sessionfactory
        }
      } catch {
        Resolve-Exception -ExceptionObject $PSitem
      }

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