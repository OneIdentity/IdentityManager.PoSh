<#!
.SYNOPSIS
Creates a new unit of work.

.DESCRIPTION
Creates and returns a new unit of work for the resolved session.

.PARAMETER Session
The session to use.

.INPUTS
None

.OUTPUTS
VI.DB.Entities.IUnitOfWork

.EXAMPLE
New-UnitOfWork
#>
function New-UnitOfWork {
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
    $Session = $null
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
      # Create new UnitOfWork instance
      $unitOfWork = ($sessionToUse).StartUnitOfWork([String][System.Guid]::NewGuid())
      $unitOfWork
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}