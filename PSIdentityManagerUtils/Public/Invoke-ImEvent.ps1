function Invoke-ImEvent() {
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
    $Session = $null,
    [parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity,
    [Parameter(Mandatory = $true, HelpMessage = 'The eventname to generate')]
    [ValidateNotNullOrEmpty()]
    [string] $EventName,
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
        $ep = New-Object 'System.Collections.Generic.Dictionary[string, object]'
        if ($EventParameters) {
          foreach ($key in $EventParameters.Keys) {
              $ep.Add($key, $EventParameters[$key])
          }
        }

        ($uow).GenerateAsync($Entity, $EventName, $ep, $noneToken).GetAwaiter().GetResult() | Out-Null
      }
      catch {
        Resolve-Exception -ExceptionObject $PSitem
      }

      Save-UnitOfWork -UnitOfWork $uow

      $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}