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
    [Parameter(Mandatory = $false, HelpMessage = 'Cmdlet prefix to use for handling multiple connections')]
    [String] $Prefix = '',
    [Parameter(Mandatory = $false, HelpMessage = 'List of modules to skip for function generation')]
    [String[]] $ModulesToSkip,
     #AAD','CSM','UCI','EBS'),
    [Parameter(Mandatory = $false, HelpMessage = 'If the switch is specified the type wrapper functions will not be created (e.g. New-Person, New-ADSAccount)')]
    [switch] $SkipFunctionGeneration = $false
  )

  Begin {
  }

  Process
  {
    # Check if there is already a session in global session store with this prefix
    if ($Global:imsessions.Contains($Prefix)) {
      throw "There is already a connection with prefix '$Prefix' defined. Please specify another prefix."
    }

    if ($FactoryName -eq 'QBM.AppServer.Client.ServiceClientFactory') {
      [System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, 'QBM.AppServer.Client.dll')) | Out-Null
    }

    # Create the session
    $factory = New-Object -TypeName $FactoryName
    $sessionfactory = [VI.DB.DbApp]::ConnectTo($ConnectionString).Using($factory).BuildSessionFactory()
    $session = [VI.DB.Sync.SyncSessionFactoryExtensions]::Open($sessionfactory, $AuthenticationString)

    # Add session to global session store
    $Global:imsessions.Add($Prefix, @{ Factory = $sessionfactory; Session = $session })

    # Generate type wrapped functions if SkipFunctionGeneration switch is not specified
    if (-not $SkipFunctionGeneration) {
        New-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip | Out-Null
        Get-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip | Out-Null
        Remove-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip | Out-Null
        Set-TypedWrapperProvider -Session $session -Prefix $Prefix -ModulesToSkip $ModulesToSkip | Out-Null
    }
  }

  End {
  }
}