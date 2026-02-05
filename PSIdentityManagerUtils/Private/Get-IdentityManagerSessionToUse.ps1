<#!
.SYNOPSIS
Resolves the session to use.

.DESCRIPTION
Returns the provided session, or resolves the current session from the global
session store when exactly one session exists.

.PARAMETER Session
The session to use.

.INPUTS
VI.DB.Entities.ISession

.OUTPUTS
VI.DB.Entities.ISession

.EXAMPLE
Get-IdentityManagerSessionToUse -Session $session
#>
function Get-IdentityManagerSessionToUse {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, Position = 0, HelpMessage = 'The session to use')]
    $Session = $null
  )

  Begin {
  }

  Process {
    try {
      # Determine session to use
      $sessionToUse = $null
      if ($null -eq $Session) {
        if ($Global:imsessions.Count -eq 1) {
          $sessionToUse = $Global:imsessions[$Global:imsessions.Keys[0]].Session
        } elseif ($Global:imsessions.Count -gt 1) {
          throw [System.InvalidOperationException] '[!] There is more than one session active. You must specify which session should be used.'
        } else {
          throw [System.InvalidOperationException] '[!] There is no session. You must open a new session with New-IdentityManagerSession before proceeding.'
        }
      } else {
        $sessionToUse = $Session
      }

      if ($null -eq $sessionToUse) {
        throw [System.InvalidOperationException] '[!] There is no session. You must open a new session with New-IdentityManagerSession before proceeding.'
      }

      $sessionToUse
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}