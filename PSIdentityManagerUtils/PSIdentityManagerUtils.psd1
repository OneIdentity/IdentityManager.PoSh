#
# Module manifest for module 'PSIdentityManagerUtils'
#

@{

    RootModule = 'PSIdentityManagerUtils.psm1'

    ModuleVersion = '0.0.5'

    Guid = 'a9a73145-c9e6-43c9-8dc9-0ab4831da948'

    Author = 'One Identity Inc.'

    CompanyName = 'One Identity Inc.'

    Copyright = '(c) 2020 One Identity Inc. All rights reserved.'

    Description = 'Provides functions to interact with the Identity Manager'

    PowerShellVersion = '5.0'

    FunctionsToExport = '*'

    CmdletsToExport = '*'

    VariablesToExport = '*'

    AliasesToExport = '*'

    PrivateData = @{
        PSData = @{
            Tags = @('IdentityManager')

            ProjectUri = 'https://github.com/OneIdentity/IdentityManager.PoSh'
        }
    }

    }