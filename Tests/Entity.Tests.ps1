. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Entity' {

    BeforeAll {
        New-IdentityManagerSession `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -FactoryName $Global:factory `
            -ProductFilePath $Global:ProductFilePath `
            -SkipFunctionGeneration
    }

    Context 'Initalize' {
        It 'Get-Entity throws on unknown session' {
            { Get-Entity -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Set-Entity throws on unknown session' {
            { Set-Entity -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'New-Entity throws on unknown session' {
            { New-Entity -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Remove-Entity throws on unknown session' {
            { Set-Entity -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Get-TableCount throws on unknown session' {
            { Get-TableCount -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Invoke-IdentityManagerScript throws on unknown session' {
            { Invoke-IdentityManagerScript -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'New-UnitOfWork throws on unknown session' {
            { New-UnitOfWork -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Remove-IdentityManagerSession throws on unknown session' {
            { Remove-IdentityManagerSession -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Set-EntityColumnValue throws on unknown session' {
            { Set-EntityColumnValue -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }
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

            { Get-Entity -Identity ($pO).XObjectKey } | Should -Throw "*Object with key $(($pO).XObjectKey) does not exist in database, you do not have the relevant viewing permissions, or an error occurred.*"
        }

    }

    Context 'Get-Entity' {

        It 'Can limit the resultsize' {
            Mock -ModuleName 'PSIdentityManagerUtils' Write-Warning {}
            (Get-Entity -Type 'DialogColumn' -ResultSize 10).Count | Should -BeExactly 10
            Assert-MockCalled -ModuleName 'PSIdentityManagerUtils' Write-Warning -Exactly 1 -Scope It -ParameterFilter { $Message -eq "There are probably more objects in the database, but the result was limited to 10 entries. To set the limit specify the -ResultSize parameter." }
        }

    }

    Context 'Get count from table' {

        It 'Get count without filter' {
            Get-TableCount -Name 'DialogDatabase'| Should -BeExactly 1
        }

        It 'Get count with valid filter' {
            Get-TableCount -Name 'DialogDatabase' -Filter '1=1' | Should -BeExactly 1
        }

        It 'Get count with invalid filter' {
            Get-TableCount -Name 'DialogDatabase' -Filter '1=2' | Should -BeExactly 0
        }

    }

    Context 'Events' {

        It 'Get-ImEvent throws on unknown session' {
            { Get-ImEvent -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Invoke-ImEvent throws on unknown session' {
            { Invoke-ImEvent -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Can get event from entity' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'EntryDate' = [DateTime]::Today.AddDays(-10)}
            $events = Get-ImEvent $pO

            $events | Should -Not -BeNullOrEmpty

            Remove-Entity -Type 'Person' -Identity ($pO).UID_Person -IgnoreDeleteDelay | Out-Null
        }

        It 'Can get event from table' {
            $e0 = Get-Entity -Type 'QBMServer' -ResultSize 1
            $events = Get-ImEvent -Identity $e0.XObjectKey

            $events | Should -Not -BeNullOrEmpty
        }

        It 'Can fire event' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'EntryDate' = [DateTime]::Today.AddDays(-10)}

            { Invoke-ImEvent $pO -EventName 'CHECK_EXITDATE'} | Should -Not -Throw

            Remove-Entity -Type 'Person' -Identity ($pO).UID_Person -IgnoreDeleteDelay | Out-Null
        }

    }

    Context 'Methods' {

        It 'Get-EntityMethod throws on unknown session' {
            { Get-EntityMethod -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Invoke-EntityMethod throws on unknown session' {
            { Invoke-EntityMethod -Session 'Unittest' } | Should -Throw '*The given value is not a valid session*'
        }

        It 'Can get method' {
            $randomLastName = [String][System.Guid]::NewGuid()
            $pO = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName; 'EntryDate' = [DateTime]::Today.AddDays(-10)}
            $methods = Get-EntityMethod $pO

            $methods | Should -Not -BeNullOrEmpty

            Remove-Entity -Type 'Person' -Identity ($pO).UID_Person -IgnoreDeleteDelay | Out-Null
        }

    }

    AfterAll {
        Get-Entity -Type 'Person' | Remove-Entity -IgnoreDeleteDelay | Out-Null
        Get-TableCount -Name 'Person' | Should -BeExactly 0
        Remove-IdentityManagerSession
    }

}