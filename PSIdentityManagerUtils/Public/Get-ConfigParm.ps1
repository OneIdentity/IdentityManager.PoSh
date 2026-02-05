<#!
.SYNOPSIS
Gets configuration parameters from Identity Manager.

.DESCRIPTION
Retrieves configuration parameters using the current or provided session. When
`Key` is specified, filters the result to a single configuration parameter.

.PARAMETER Session
The session to use. If not provided, the default session is resolved.

.PARAMETER Key
The config parameter key to query for. If empty, all parameters are returned.

.INPUTS
None

.OUTPUTS
System.Object

.EXAMPLE
Get-ConfigParm

.EXAMPLE
Get-ConfigParm -Key 'Common\Mail\SMTPHost'
#>
function Get-ConfigParm {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
        [ValidateScript({
            try {
                $_.GetType().ImplementedInterfaces.Contains([type]'VI.DB.Entities.ISession')
            }
            catch [System.Management.Automation.PSInvalidCastException] {
                throw [System.Management.Automation.PSInvalidCastException] 'The given value is not a valid session.'
            }
        })]
        $Session = $null,
        [parameter(Mandatory = $false, HelpMessage = 'The configparm key to query for')]
        [string] $Key = ''
    )

    Begin {
        try {
            # Determine session to use
            $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
            if ($null -eq $sessionToUse) {
                throw [System.ArgumentNullException] 'Session'
            }
        } catch {
            Resolve-Exception -ExceptionObject $PSitem
        }
    }

    Process {
        try {
            $resolve = $sessionToUse.Factory.CommonServices.GetType().GetMethod('Resolve')
            $iConfigData = $resolve.MakeGenericMethod([VI.DB.MetaData.IConfigDataProvider])
            $configdata = $iConfigData.Invoke($sessionToUse.Factory.CommonServices, $null)

            $cd = $configdata.GetConfigDataAsync([System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
            if ([string]::IsNullOrEmpty($Key.Trim())) {
                $cd
            } else {
                $cd | Where-Object { $_.FullPath.ToString() -eq $Key }
            }
        }
        catch {
            Resolve-Exception -ExceptionObject $PSitem
        }
    }

    End {
    }
}

