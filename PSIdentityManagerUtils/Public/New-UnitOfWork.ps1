function New-UnitOfWork {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null
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
      return $unitOfWork
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}