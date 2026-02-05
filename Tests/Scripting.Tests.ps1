. $PSScriptRoot\Integrationtest.Config.ps1

Describe 'Scripting' {

    BeforeAll {
        New-IdentityManagerSession `
            -ConnectionString $Global:connectionString `
            -AuthenticationString $Global:authenticationString `
            -ProductFilePath $Global:ProductFilePath `
            -SkipFunctionGeneration
    }

    Context 'Running scripts' {

        It 'Will fail on non-existing script' {          
            { Invoke-IdentityManagerScript -Name 'FooBar' } | Should -Throw "*The script 'FooBar' could not be found.*"
        }

        It 'Can run a script and fetch return value' {
            $params = @('Common')
            $configParmValue = Invoke-IdentityManagerScript -Name 'QBM_GetConfigParmValue' -Parameters $params
            $configParmValue | Should -Not -BeNullOrEmpty

            $pV = Get-Entity -Type 'DialogConfigparm' -Filter "Fullpath = '$($params[0])'"
            $configParmValue | Should -BeExactly $pV.Value
        }

        It 'Can run a script with multiple parameters' {
            $params = @('foo=bar;hello=world', 'foo', 'baz', $false)
            $r = Invoke-IdentityManagerScript -Name 'DPR_Append2ConnectionString' -Parameters $params
            "foo=baz;hello=world" | Should -BeExactly $r
        }

        It 'Can run a script with parameter of type ParamArray' {
            $params = @('foo', 'bar', 'baz')
            $r = Invoke-IdentityManagerScript -Name 'VID_PathCombine' -Parameters $params
            "foo$([System.IO.Path]::DirectorySeparatorChar)bar$([System.IO.Path]::DirectorySeparatorChar)baz" | Should -BeExactly $r
        }

        It 'Can handle errors' {
            $params = @('Unittest')
            { Invoke-IdentityManagerScript -Name 'QBM_GetConfigParmValue' -Parameters $params } | Should -Throw "*does not exist or is not set. It is a mandatory value and must be configured in your system.*"
        }

    }

    AfterAll {
        Remove-IdentityManagerSession
    }

}