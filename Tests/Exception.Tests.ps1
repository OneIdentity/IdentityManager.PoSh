. $PSScriptRoot\Integrationtest.Config.ps1

# make sure our exception handler function is loaded
. "$PSScriptRoot\..\PSIdentityManagerUtils\Private\common.ps1"

Describe 'Resolve-Exception' {

    BeforeAll {
        $Error.Clear()
    }

    Context 'Can handle exception' {

        It 'Does throw on null' {
            { Resolve-Exception -ExceptionObject $null } | Should -Throw
        }

        It 'Does not throw if desired' {
            {
                . "$PSScriptRoot\..\PSIdentityManagerUtils\Private\common.ps1"

                $ex = New-Object System.Management.Automation.RuntimeException 'UnittestEx'
                $mockExceptionObject = [PsCustomObject]@{
                    ScriptStackTrace = "Empty ScriptStackTrace"
                    StackTrace = "Empty StackTrace"
                    Exception = $ex
                }
                Resolve-Exception -ExceptionObject $mockExceptionObject -CustomErrorAction 'SilentlyContinue'
            } | Should -Not -Throw
        }

        It 'Does throw' {
            {
                $ex = New-Object System.Management.Automation.RuntimeException 'UnittestEx'
                $mockExceptionObject = [PsCustomObject]@{
                    ScriptStackTrace = "Empty ScriptStackTrace"
                    StackTrace = "Empty StackTrace"
                    Exception = $ex
                }

                Resolve-Exception -ExceptionObject $mockExceptionObject
            } | Should -Throw
        }
    }
}



