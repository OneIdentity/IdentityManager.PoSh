. $PSScriptRoot\Integrationtest.Config.ps1

# make sure our exception handler function is loaded
. "$PSScriptRoot\..\PSIdentityManagerUtils\Private\common.ps1"

Describe 'Resolve-Exception' {

    BeforeAll {
        $Error.Clear()
    }

    Context 'Can handle exception' {

        It 'Does throw on null' {
            { Resolve-Exception -ExceptionObject $null } |Should -Throw
        }

        # It 'Does not throw on New-Object' {
        #     { Resolve-Exception -ExceptionObject New-Object } |Should -Not -Throw
        # }

        # It 'Does handle exception' {
        #     $Error.Clear()
        #     {
        #         try {
        #             throw 'unittest'
        #         } catch {
        #             Resolve-Exception -ExceptionObject $PSitem
        #         }
        #     } |Should -Throw '*unittest*'

        #     $Error[0].Exception.Message.Contains('---[StackTrace]---') |Should -BeTrue
        # }

        # It 'Can hide stack trace' {
        #     $Error.Clear()
        #     {
        #         try {
        #             throw 'unittest'
        #         } catch {
        #             Resolve-Exception -ExceptionObject $PSitem -HideStackTrace
        #         }
        #     } |Should -Throw '*unittest*'

        #     $Error[0].Exception.Message.Contains('---[StackTrace]---') |Should -BeFalse
        # }
    }
}



