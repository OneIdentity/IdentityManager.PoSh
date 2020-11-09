function Get-Authentifier {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $true, HelpMessage = 'Connectionstring to an Identity Manager database')]
        [ValidateNotNullOrEmpty()]
        [String] $ConnectionString,
        [Parameter(Mandatory = $false, HelpMessage = 'The connection factory to use')]
        [ValidateSet('VI.DB.ViSqlFactory', 'VI.DB.Oracle.ViOracleFactory', 'QBM.AppServer.Client.ServiceClientFactory')]
        [String] $FactoryName = 'VI.DB.ViSqlFactory',
        [Parameter(Mandatory = $false, HelpMessage = 'The product to query for authentication methods')]
        [ValidateSet('API Designer', 'Application Server', 'Default', 'Designer', 'LaunchPad', 'Manager', 'OperationsSupportWebPortal', 'PasswordReset', 'SOAP Service', 'SPML Service', 'WebDesigner', 'WebDesignerEditor')]
        [String] $Product = 'Manager'
    )
  
    Begin {
    }

    Process {
        if ($FactoryName -eq 'QBM.AppServer.Client.ServiceClientFactory') {
            [System.Reflection.Assembly]::LoadFrom([io.path]::combine($oneImBasePath, 'QBM.AppServer.Client.dll')) | Out-Null
        }

        $factory = New-Object -TypeName $FactoryName
        $sessionfactory = [VI.DB.DbApp]::ConnectTo($ConnectionString).Using($factory).BuildSessionFactory()

        $resolve = $sessionfactory.CommonServices.GetType().GetMethod('Resolve')
        $authmoduleInfoSourceInterface = $resolve.MakeGenericMethod([VI.DB.Auth.IAuthModuleInfoSource])
        $authmoduleInfoSource = $authmoduleInfoSourceInterface.Invoke($sessionfactory.CommonServices, @())
        $modules = $authmoduleInfoSource.GetUIAuthentifiersAsync($Product, $noneToken).GetAwaiter().GetResult() | Select-Object Caption, Ident

        Write-Output $modules
    }

    End {
    }
}

