. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Get-ConfigParm' {

    BeforeAll {
        New-IdentityManagerSession `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -ProductFilePath $Global:ProductFilePath `
            -SkipFunctionGeneration
    }

    Context 'ConfigParm' {

        It 'Can get all ConfigParms' {
            $x = Get-ConfigParm
            $x | Should -Not -BeNullOrEmpty
        }

        It 'All Configparms include Common' {
            $x = Get-ConfigParm
            $y = $x | Where-Object { $_.FullPath -eq 'Common' }
            $y.FullPath | Should -Be 'Common'
            $y.Value | Should -Be 1
        }

        It 'Can query for a specific ConfigParm' {
            $x = Get-ConfigParm `
                -Key 'Common'
            $x | Should -Not -BeNullOrEmpty
            $x.FullPath | Should -Be 'Common'
            $x.Value | Should -Be 1
        }

        It 'Can query for a specific ConfigParm with a different casing' {
            $x = Get-ConfigParm `
                -Key 'comMoN'
            $x | Should -Not -BeNullOrEmpty
            $x.FullPath | Should -Be 'Common'
            $x.Value | Should -Be 1
        }

        It 'Can get value from ConfigParm' {
            $x = Get-ConfigParm `
                -Key 'Common'
            $x | Should -Not -BeNullOrEmpty
            $x.Value | Should -Be 1
        }
    }
    
    AfterAll {
        Remove-IdentityManagerSession
    }
}