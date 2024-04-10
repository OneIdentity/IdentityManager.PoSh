. $PSScriptRoot\Integrationtest.Config.ps1

$DebugPreference = 'Continue'

Describe 'Entity performance' {

    BeforeAll {
        New-IdentityManagerSession `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -FactoryName $Global:factory `
            -ProductFilePath $Global:ProductFilePath `
            -SkipFunctionGeneration
    }

    Context 'Create entities' {

        It 'Can create entity - single operation' {
            $randomLastName = [String][System.Guid]::NewGuid()

            $st = $(Get-Date)
            $p = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Entity created in $($et.TotalSeconds) seconds"

            $p | Should -Not -BeNullOrEmpty

            Get-TableCount -Name 'Person'| Should -BeExactly 1

            $st = $(Get-Date)
            Remove-Entity -Type 'Person' -Identity ($p).UID_Person -IgnoreDeleteDelay |Out-Null
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Entity removed in $($et.TotalSeconds) seconds"
        }

        It 'Can create 100 entities - single operation' {
            $Quantity = 100

            $tt = $(Get-Date)

            $AvgEntityCreateTime = 0
            for ($i = 1; $i -le $Quantity; $i++) {
                $randomLastName = [String][System.Guid]::NewGuid()

                $st1 = $(Get-Date)
                $p = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName}
                $et1 = New-TimeSpan $st1 $(Get-Date)
                $AvgEntityCreateTime += $et1.TotalSeconds

                $p | Should -Not -BeNullOrEmpty
            }
            Write-Debug "`t==> Avg. entity created (direct save) in $($AvgEntityCreateTime / $Quantity) seconds"

            $ett = New-TimeSpan $tt $(Get-Date)
            Write-Debug "$Quantity entities (direct save) created in $($ett.TotalSeconds) seconds"

            Get-TableCount -Name 'Person'| Should -BeExactly $Quantity

            $st = $(Get-Date)
            Get-Entity -Type 'Person' | Remove-Entity -IgnoreDeleteDelay |Out-Null
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "$Quantity entities removed in $($et.TotalSeconds) seconds"
        }

        It 'Can create entity - batch operation' {
            $randomLastName = [String][System.Guid]::NewGuid()

            $st = $(Get-Date)
            $p = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName} -Unsaved
            $p | Should -Not -BeNullOrEmpty
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Entity created in memory in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            $uow = New-UnitOfWork
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Unit of work created in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            Add-UnitOfWorkEntity $uow -Entity $p
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Entity added to Unit of work in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            Save-UnitOfWork $uow
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Unit of work saved to database in $($et.TotalSeconds) seconds"

            Get-TableCount -Name 'Person'| Should -BeExactly 1

            $st = $(Get-Date)
            Remove-Entity -Type 'Person' -Identity ($p).UID_Person -IgnoreDeleteDelay |Out-Null
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Entity removed in $($et.TotalSeconds) seconds"
        }

        It 'Can create 100 entities - batch operation' {
            $Quantity = 100

            $tt = $(Get-Date)

            $stu = $(Get-Date)
            $uow = New-UnitOfWork
            $etu = New-TimeSpan $stu $(Get-Date)
            Write-Debug "Unit of work created in $($etu.TotalSeconds) seconds"

            $AvgEntityCreateTime = 0
            $AvgUnitOfWorkTime = 0
            for ($i = 1; $i -le $Quantity; $i++) {
                $randomLastName = [String][System.Guid]::NewGuid()

                $st1 = $(Get-Date)
                $p = New-Entity -Type 'Person' -Properties @{'FirstName' = 'Max'; 'LastName' = $randomLastName} -Unsaved
                $et1 = New-TimeSpan $st1 $(Get-Date)
                $AvgEntityCreateTime += $et1.TotalSeconds

                $st2 = $(Get-Date)
                Add-UnitOfWorkEntity $uow -Entity $p
                $et2 = New-TimeSpan $st2 $(Get-Date)
                $AvgUnitOfWorkTime += $et2.TotalSeconds
            }
            Write-Debug "`t==> Avg. entity created in memory in $($AvgEntityCreateTime / $Quantity) seconds"
            Write-Debug "`t==> Avg. Entity added to Unit of work in $($AvgUnitOfWorkTime / $Quantity) seconds"

            $ett = New-TimeSpan $tt $(Get-Date)
            Write-Debug "$Quantity entities (batch) created in $($ett.TotalSeconds) seconds"

            $st = $(Get-Date)
            Save-UnitOfWork $uow
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Unit of work saved to database in $($et.TotalSeconds) seconds"

            Get-TableCount -Name 'Person'| Should -BeExactly $Quantity

            $st = $(Get-Date)
            Get-Entity -Type 'Person' | Remove-Entity -IgnoreDeleteDelay |Out-Null
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "$Quantity entities removed in $($et.TotalSeconds) seconds"
        }

    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}

Describe 'Typped wrapper performance' {

    BeforeAll {
        New-IdentityManagerSession `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -FactoryName $Global:factory `
            -ProductFilePath $Global:ProductFilePath `
            -ModulesToAdd $Global:modulesToAdd
    }

    Context 'Create entities' {
        It 'Can create entity - batch operation' {
            $randomLastName = [String][System.Guid]::NewGuid()

            $st = $(Get-Date)
            $p = New-Person -FirstName 'Max' -LastName "$randomLastName" -Unsaved
            $p | Should -Not -BeNullOrEmpty
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Person created in memory in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            $uow = New-UnitOfWork
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Unit of work created in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            Add-UnitOfWorkEntity $uow -Entity $p
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Person added to Unit of work in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            Save-UnitOfWork $uow
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Unit of work saved to database in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            Remove-Entity -Type 'Person' -Identity ($p).UID_Person -IgnoreDeleteDelay |Out-Null
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Person removed in $($et.TotalSeconds) seconds"
        }

        It 'Can create 100 entities - batch operation' {
            $Quantity = 100

            $tt = $(Get-Date)

            $stu = $(Get-Date)
            $uow = New-UnitOfWork
            $etu = New-TimeSpan $stu $(Get-Date)
            Write-Debug "Unit of work created in $($etu.TotalSeconds) seconds"

            $AvgEntityCreateTime = 0
            $AvgUnitOfWorkTime = 0
            for ($i = 1; $i -le $Quantity; $i++) {
                $randomLastName = [String][System.Guid]::NewGuid()

                $st1 = $(Get-Date)
                $p = New-Person -FirstName 'Max' -LastName "$randomLastName" -Unsaved
                $et1 = New-TimeSpan $st1 $(Get-Date)
                $AvgEntityCreateTime += $et1.TotalSeconds

                $st2 = $(Get-Date)
                Add-UnitOfWorkEntity $uow -Entity $p
                $et2 = New-TimeSpan $st2 $(Get-Date)
                $AvgUnitOfWorkTime += $et2.TotalSeconds
            }
            Write-Debug "`t==> Avg. entity created (typped wrapper) in memory in $($AvgEntityCreateTime / $Quantity) seconds"
            Write-Debug "`t==> Avg. Entity added to Unit of work in $($AvgUnitOfWorkTime / $Quantity) seconds"

            $ett = New-TimeSpan $tt $(Get-Date)
            Write-Debug "$Quantity entities (typped wrapper + batch) created in $($ett.TotalSeconds) seconds"

            $st = $(Get-Date)
            Save-UnitOfWork $uow
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "Unit of work saved to database in $($et.TotalSeconds) seconds"

            $st = $(Get-Date)
            Get-Entity -Type 'Person' | Remove-Entity -IgnoreDeleteDelay |Out-Null
            $et = New-TimeSpan $st $(Get-Date)
            Write-Debug "$Quantity entities removed in $($et.TotalSeconds) seconds"
        }
    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}