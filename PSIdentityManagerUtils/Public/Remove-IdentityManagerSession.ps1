function Remove-IdentityManagerSession {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $false, HelpMessage = 'Prefix specified while creating the connection')]
    [String] $Prefix = '',
    [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = 'Session to remove')]
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
  }

  Process {
    try {

      $foundPrefix = $null
      $entry = $null

      if ($null -ne $Session) {
        $foundPrefix = $Global:imsessions.Keys | Where-Object { $Global:imsessions[$_].Session -eq $Session }
        $entry = $Global:imsessions[$foundPrefix]
      } elseif ($Global:imsessions.Contains($Prefix)) {
        $foundPrefix = $Prefix
        $entry = $Global:imsessions[$Prefix]
      }

      if ($null -ne $entry) {
        if ($null -ne $entry.Session) {
          $entry.Session.Dispose()
        }

        if ($null -ne $entry.Factory) {
          $entry.Factory.Dispose()
        }

        $Global:imsessions.Remove($foundPrefix)
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}