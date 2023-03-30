. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Get-TableCount' {

    BeforeAll {
        New-IdentityManagerSession -ConnectionString $Global:connectionString -AuthenticationString $Global:authenticationString -FactoryName $Global:factory -ModulesToSkip $Global:modulesToSkip
    }

    Context 'Get count from table' {

        It 'Get count without filter' {
            Get-TableCount -Name 'DialogDatabase'| Should -BeExactly 1
        }

        It 'Get count with valid filter' {
            Get-TableCount -Name 'DialogDatabase' -Filter '1=1'| Should -BeExactly 1
        }

        It 'Get count with invalid filter' {
            Get-TableCount -Name 'DialogDatabase' -Filter '1=2'| Should -BeExactly 0
        }
    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}