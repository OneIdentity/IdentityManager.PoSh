 . $PSScriptRoot\Integrationtest.Config.ps1

Describe 'New-IdentityManagerSession' {

    Context 'Single session' {

        It 'Can open a new session' {
            { New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -ModulesToAdd $Global:modulesToAdd
            } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 1
        }

        It 'Throws on open the same session' {
            { New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -ModulesToAdd $Global:modulesToAdd
            } | Should -Throw '*There is already a connection with prefix*'
            $Global:imsessions.Count | Should -Be 1
        }

        It 'Can close a session 1' {
            { Remove-IdentityManagerSession } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

        It 'Can close a session a second time' {
            { Remove-IdentityManagerSession } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

        It 'Can open a new session with prefix' {
            $sess = New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -ModulesToAdd $Global:modulesToAdd `
                -Prefix 'UT'
            $sess | Should -Not -BeNullOrEmpty
            $Global:imsessions.Count | Should -Be 1
            $Global:imsessions.ContainsKey('UT') | Should -BeTrue
        }

        It 'Can close a session with prefix' {
            { Remove-IdentityManagerSession -Prefix 'UT' } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

        It 'Can open a new session without any wrapper function' {
            { New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -SkipFunctionGeneration
            } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 1
        }

        It 'Can close a session 2' {
            { Remove-IdentityManagerSession } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

        It 'Can open a new session with skipping some wrapper function' {
            { New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -ModulesToSkip $Global:modulesToSkip `
            } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 1
        }

        It 'Can close a session 3' {
            { Remove-IdentityManagerSession } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

        It 'Can open and close a session' {
            $sess = New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -SkipFunctionGeneration
            $sess | Should -Not -BeNullOrEmpty
            $Global:imsessions.Count | Should -Be 1

            { Remove-IdentityManagerSession -Session $sess } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

        It 'Can open and close a session twice' {
            $sess = New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -SkipFunctionGeneration
            $sess | Should -Not -BeNullOrEmpty
            $Global:imsessions.Count | Should -Be 1

            { Remove-IdentityManagerSession -Session $sess } | Should -Not -Throw
            { Remove-IdentityManagerSession -Session $sess } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

    }

    Context 'Multiple sessions' {

        It 'Can open multiple sessions' {
            {
                New-IdentityManagerSession `
                -ConnectionString $Global:connectionString `
                -AuthenticationString $Global:authenticationString `
                -ProductFilePath $Global:ProductFilePath `
                -ModulesToAdd $Global:modulesToAdd `
                -Prefix S1

                New-IdentityManagerSession `
                -ConnectionString $Global:connectionString2 `
                -AuthenticationString $Global:authenticationString2 `
                -ProductFilePath $Global:ProductFilePath2 `
                -ModulesToAdd $Global:modulesToAdd `
                -Prefix S2
            } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 2
        }

        It 'Can close multiple sessions with prefix' {
            { Remove-IdentityManagerSession -Prefix 'S1' } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 1

            { Remove-IdentityManagerSession -Prefix 'S2' } | Should -Not -Throw
            $Global:imsessions.Count | Should -Be 0
        }

    }
}