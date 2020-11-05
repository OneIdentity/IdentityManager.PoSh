function Get-IdentityManagerSessionToUse {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, Position = 0, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null
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
        }
      } else {
        $sessionToUse = $Session
      }

      return $sessionToUse
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}