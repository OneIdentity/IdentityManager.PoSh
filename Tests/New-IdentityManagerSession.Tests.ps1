 . $PSScriptRoot\Integrationtest.Config.ps1

Describe 'New-IdentityManagerSession' {

    It 'Open a new session' {
        New-IdentityManagerSession -ConnectionString $Global:connectionString -AuthenticationString $Global:authenticationString -FactoryName $Global:factory -ModulesToSkip $Global:modulesToSkip | Should -Not -Be $null
    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}