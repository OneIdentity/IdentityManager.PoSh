. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Entity' {

    BeforeAll {
        New-IdentityManagerSession -ConnectionString $Global:connectionString -AuthenticationString $Global:authenticationString -FactoryName $Global:factory -ModulesToSkip $Global:modulesToSkip
    }

    Context 'Create entities' {
        It 'Can create a new entity' {

            $randomLastName = [String][System.Guid]::NewGuid()
            $p = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
            $p | Should -Not -BeNullOrEmpty

            $pCol = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"
            $pCol.Count | Should -BeExactly 1

            $p.UID_Person | Should -BeExactly $pCol.UID_Person
        }
    }

    Context 'Modify entities' {

        It 'Can modify person I' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
            $pM = Set-Entity -Type 'Person' -Identity ($pO).UID_Person -Properties @{'CustomProperty01' = 'IntegrationTest'}
            $pV = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person II' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'CustomProperty01' = 'IntegrationTest'}
            $pM = Set-Entity -Type 'Person' -Identity ($pO).UID_Person -Properties @{'CustomProperty01' = 'Test'}
            $pV = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person III' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'CustomProperty01' = 'IntegrationTest'}
            $pM = Set-Entity -Type 'Person' -Identity ($pO).UID_Person -Properties @{'CustomProperty01' = ''}
            $pV = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person IV' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'CustomProperty01' = 'IntegrationTest'}
            $pM = Set-Entity -Type 'Person' -Identity ($pO).UID_Person -Properties @{'CustomProperty01' = $null}
            $pV = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"

            $pM.CustomProperty01 | Should -BeExactly $pV.CustomProperty01
        }

        It 'Can modify person V' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'EntryDate' = [DateTime]::Today.AddDays(-10)}
            $pM = Set-Entity -Type 'Person' -Identity ($pO).UID_Person -Properties @{'EntryDate' = $null}
            $pV = Get-Entity -Type 'Person' -Filter "Lastname = '$randomLastName'"

            $pM.EntryDate | Should -BeExactly $pV.EntryDate
        }

    }

    Context 'Remove entities' {

        It 'Can remove person' {
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