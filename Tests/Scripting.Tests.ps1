. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Scripting' {

    BeforeAll {
        New-IdentityManagerSession `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -FactoryName $Global:factory `
            -ProductFilePath $Global:ProductFilePath `
            -SkipFunctionGeneration
    }

    Context 'Running scripts' {

        It 'Will fail on non-existing script' {          
            { Invoke-IdentityManagerScript -Name 'FooBar' } | Should -Throw '*Script block FooBar not found.*'
        }      

        It 'Can run a script and fetch return value' {
            $params = @('Common')
            $configParmValue = Invoke-IdentityManagerScript -Name 'QBM_GetConfigParmValue' -Parameters $params
            $configParmValue | Should -Not -BeNullOrEmpty

            $pV = Get-Entity -Type 'DialogConfigparm' -Filter "Fullpath = '$($params[0])'"
            $configParmValue | Should -BeExactly $pV.Value
        }

        It 'Can handle errors' {
            $params = @('Unittest')
            { Invoke-IdentityManagerScript -Name 'QBM_GetConfigParmValue' -Parameters $params } | Should -Throw "*The configuration parameter 'Unittest' does not exist or is not set. It is a mandatory value and must be configured in your system.*"
        }

    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}