. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Entity' {

    BeforeAll {
        New-IdentityManagerSession  `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -FactoryName $Global:factory `
            -ProductFilePath $Global:ProductFilePath `
            -ModulesToAdd $Global:modulesToAdd
    }

    Context 'Create typed wrapper object Person' {

        It 'Can create a person' {

            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Person -Lastname "$randomLastName"
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }

        It 'Can create another person' {

            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Person -Identity $p.UID_Person
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }

    }

    Context 'Modify typed wrapper object Person' {

        It 'Can modify person' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Person -FirstName 'Max' -LastName "$randomLastName"
            $pM = Set-Person -Entity $pO -CustomProperty01 'IntegrationTest'
            $pV = Get-Person -Lastname "$randomLastName"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person by pipeline' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Person -FirstName 'Max' -LastName "$randomLastName" | Set-Person -CustomProperty01 'IntegrationTest'
            $pV = Get-Person -Lastname "$randomLastName"

            $pO.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person by pipeline with overwrite' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Person -FirstName 'Max' -LastName "$randomLastName" -CustomProperty01 'IntegrationTest' | Set-Person -CustomProperty01 'Test'
            $pV = Get-Person -Lastname "$randomLastName"

            $pO.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person by pipeline with reset' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Person -FirstName 'Max' -LastName "$randomLastName" -CustomProperty01 'IntegrationTest' | Set-Person -CustomProperty01 $null
            $pV = Get-Person -Lastname "$randomLastName"

            $pO.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

    }

    Context 'Remove typed wrapper object Person' {

        It 'Can remove person' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO =  New-Person -FirstName 'Max' -LastName "$randomLastName"
            Remove-Person -Entity $pO -IgnoreDeleteDelay
            (Get-Person -Lastname "$randomLastName").Count | Should -BeExactly 0
        }

    }

    AfterAll {
        Get-Entity -Type 'Person' | Remove-Entity -IgnoreDeleteDelay |Out-Null
        Get-TableCount -Name 'Person' | Should -BeExactly 0
        Remove-IdentityManagerSession
    }

}