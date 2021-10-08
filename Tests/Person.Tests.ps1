. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Entity' {

    BeforeAll {
        New-IdentityManagerSession -ConnectionString $Global:connectionString -AuthenticationString $Global:authenticationString -FactoryName $Global:factory -ModulesToSkip $Global:modulesToSkip
    }

    Context 'Create typed wrapper object Person' {

        It 'Create a new person I' {

            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Person -Lastname "$randomLastName"
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }

        It 'Create a new person II' {

            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Person -Identity $p.UID_Person
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }

    }

    Context 'Modify typed wrapper object Person' {

        It "Modify person I" {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $pM = Set-Person -Entity $pO -CustomProperty01 'IntegrationTest'
            $pV = Get-Person -Lastname "$randomLastName"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It "Modify person II" {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Person -FirstName 'Max' -LastName "$randomLastName" |Set-Person -CustomProperty01 'IntegrationTest'
            $pV = Get-Person -Lastname "$randomLastName"

            $pO.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

    }

    Context 'Remove typed wrapper object Person' {

        It "Remove person" {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO =  New-Person -FirstName 'Max' -LastName "$randomLastName"
            Remove-Person -Entity $pO -IgnoreDeleteDelay
            (Get-Person -Lastname "$randomLastName").Count | Should -BeExactly 0
        }

    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}