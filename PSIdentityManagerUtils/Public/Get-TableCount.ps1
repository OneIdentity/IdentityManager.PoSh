function Get-TableCount() {
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object')]
    [string] $Name,
    [parameter(Mandatory = $false, HelpMessage = 'Specify a SQL where clause to filter the result')]
    [string] $Filter = ''
  )

  Begin {
    try {
      # Determine session to use
      $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
      if ($null -eq $sessionToUse) {
        throw [System.ArgumentNullException] 'Session'
      }
      $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  Process {
    try {

      $query = [VI.DB.Entities.Query]::From($Name).Where($Filter).SelectCount()
      $result = $src.GetCountAsync($query, $noneToken).GetAwaiter().GetResult()

      Write-Output $result
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}