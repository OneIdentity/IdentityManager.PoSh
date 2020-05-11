function Remove-IdentityManagerSession {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $false, HelpMessage = 'Prefix specified while creating the connection')]
    [String] $Prefix = '',
    [Parameter(Mandatory = $false, HelpMessage = 'Session to remove')]
    [VI.DB.Entities.ISession] $Session = $null
  )

  Begin {
  }

  Process
  {
    $foundPrefix = $null
    $entry = $null

    if ($null -ne $Session) {
      $foundPrefix = $Global:imsessions.Keys | Where-Object { $Global:imsessions[$_].Session -eq $Session }
      $entry = $Global:imsessions[$foundPrefix]
    } elseif ($Global:imsessions.Contains($Prefix)) {
      $foundPrefix = $Prefix
      $entry = $Global:imsessions[$Prefix]
    }

    if ($null -ne $entry)
    {
      if ($null -ne $entry.Session)
      {
        $entry.Session.Dispose()
      }

      if ($null -ne $entry.Factory)
      {
        $entry.Factory.Dispose()
      }

      $Global:imsessions.Remove($foundPrefix)
    }
  }

  End {
  }
}