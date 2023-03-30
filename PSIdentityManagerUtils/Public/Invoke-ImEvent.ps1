function Invoke-ImEvent() {
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

      # Load object by identity
      $Entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity -Entity $Entity

      $uow = New-UnitOfWork -Session $sessionToUse

      try {
        ($uow).GenerateAsync($Entity, $EventName, $EventParameters, $noneToken).GetAwaiter().GetResult() | Out-Null
      }
      catch {
        Resolve-Exception -ExceptionObject $PSitem
      }

      Save-UnitOfWork -UnitOfWork $uow

      return $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}