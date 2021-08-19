. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Entity' {

    BeforeAll {
        New-IdentityManagerSession -ConnectionString $Global:connectionString -AuthenticationString $Global:authenticationString -FactoryName $Global:factory -ModulesToSkip $Global:modulesToSkip
    }

    Context 'Create entities' {
        It 'Create a new entity' {

            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }

        It 'Create a new person' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }
    }

    Context 'Modify entities' {

        It "Modify person" {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
            $pM = Set-Entity -Type 'Person' -Identity ($pO).UID_Person -Properties @{'CustomProperty01' = 'IntegrationTest'}
            $pV = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

    }

    Context 'Remove entities' {

        It "Remove person" {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
            Remove-Entity -Type 'Person' -Identity ($pO).UID_Person -IgnoreDeleteDelay
            (Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'").Count | Should -BeExactly 0
        }

    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}