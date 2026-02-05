<#!
.SYNOPSIS
Invokes an Identity Manager script.

.DESCRIPTION
Runs a script by name within the Identity Manager scripting environment, passing
optional parameters and returning the result.

.PARAMETER Session
The session to use.

.PARAMETER Name
The name of the script.

.PARAMETER Parameters
Script parameters.

.INPUTS
None

.OUTPUTS
System.Object

.EXAMPLE
Invoke-IdentityManagerScript -Name 'QBM_Person_SetAccountName' -Parameters @($uid)
#>
function Invoke-IdentityManagerScript {
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
    [parameter(Mandatory = $true, HelpMessage = 'The name of the script')]
    [ValidateNotNullOrEmpty()]
    [string] $Name,
    [parameter(Mandatory = $false, HelpMessage = 'The script parameters')]
    [object[]] $Parameters = @()
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
      $scriptEnv = [VI.DB.Entities.SessionExtensions]::Scripts($sessionToUse)
      $scriptClass = $scriptEnv['scripts']
      $scriptRunner = New-Object 'VI.DB.Scripting.ScriptRunner' -ArgumentList @($scriptClass, $sessionToUse)

      $method = $scriptClass[$Name]

      if ( -not $method) {
        throw "The script '$Name' could not be found."
      }

      $methodParameters = $method.GetParameters()
      Write-Debug "The script $Name has $(($methodParameters).Length) parameter(s). The provided parameter array has a length of $($Parameters.Length)."

      # Check if the method has a ParamArray parameter and wrap parameters accordingly
      if ($methodParameters.Length -gt 0 -and $methodParameters[-1].IsDefined([System.ParamArrayAttribute], $false)) {
        Write-Debug "The script $Name has a ParamArray parameter. Wrapping parameters."
        # Get the element type of the ParamArray parameter
        $paramArrayType = $methodParameters[-1].ParameterType.GetElementType()
        Write-Debug "ParamArray element type: $($paramArrayType.FullName)"

        # Convert the parameters to a strongly-typed array
        $typedArray = [Array]::CreateInstance($paramArrayType, $Parameters.Length)
        for ($i = 0; $i -lt $Parameters.Length; $i++) {
          $typedArray[$i] = $Parameters[$i]
        }

        # Create a single-element array containing the typed parameters array
        $wrappedParams = [object[]]::new(1)
        $wrappedParams[0] = $typedArray
        $Parameters = $wrappedParams
      }

      # register events
      $registeredEvents = New-Object System.Collections.ArrayList
      $registeredEvents.Add((Register-ObjectEvent -InputObject $scriptRunner.Data -EventName 'Message' -Action { Write-Output $EventArgs.Text })) | Out-Null
      $registeredEvents.Add((Register-ObjectEvent -InputObject $scriptRunner.Data -EventName 'Progress' -Action { Write-Output $EventArgs.Text })) | Out-Null

      $result = $null
      try {
        # run script
        $result = $scriptRunner.Eval($Name, $Parameters)
      }
      finally {
        # unregister events
        $registeredEvents | ForEach-Object { Unregister-Event -SubscriptionId $_.Id -ErrorAction 'SilentlyContinue' }
      }

      $result
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}