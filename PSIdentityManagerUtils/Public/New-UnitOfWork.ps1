function New-UnitOfWork {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null
  )

  Begin {
    # Determine Session to use
    $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
    if($null -eq $sessionToUse) {
      throw [System.ArgumentNullException] 'Session'
    }
  }

  Process {
    # Create new UnitOfWork instance
    $unitOfWork = ($sessionToUse).StartUnitOfWork([String][System.Guid]::NewGuid())
    return $unitOfWork
  }

  End {
  }
}