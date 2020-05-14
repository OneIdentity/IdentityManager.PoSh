function Invoke-Event() {
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, ValueFromPipeline=$true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity,
    [Parameter(Mandatory = $true, HelpMessage = 'The eventname to generate')]
    [ValidateNotNullOrEmpty()]
    [String] $EventName,
    [Parameter(Mandatory = $false, HelpMessage = 'The parameter key value pairs for the event')]
    [Hashtable] $EventParameters
  )

  Begin {
    # Determine Session to use
    $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
    if($null -eq $sessionToUse) {
      throw [System.ArgumentNullException] 'Session'
    }
  }

  Process {
    # Load Object by Identity
    $Entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity -Entity $Entity

    $uow = New-UnitOfWork -Session $sessionToUse

    try {
      ($uow).GenerateAsync($Entity, $EventName, $EventParameters, $noneToken).GetAwaiter().GetResult() | Out-Null
    }
    catch {
      $e = $_.Exception
      $msg = $e.Message
      while ($e.InnerException) {
        $e = $e.InnerException
        $msg += "`n" + $e.Message
      }
      write-host $msg
    }

    Save-UnitOfWork -UnitOfWork $uow

    return $Entity
  }

  End {

  }
}