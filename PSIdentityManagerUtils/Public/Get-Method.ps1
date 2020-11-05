function Get-Method() {
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, ValueFromPipeline=$true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity
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

      $objectMethods = [VI.DB.Entities.Entity]::GetEntityMethodsAsync($Entity, $sessionToUse, $null, $noneToken).GetAwaiter().GetResult()

      Write-Host 'Object methods'
      ForEach ($om in $objectMethods) {
        Write-Host "`t" $om.Caption.Original
      }

      $customizerMethods = [VI.DB.Entities.Entity]::GetMethodsAsync($Entity, $sessionToUse, $noneToken).GetAwaiter().GetResult()
      Write-Host 'Customizer methods'
      ForEach ($cm in $customizerMethods) {
        Write-Host "`t" $cm.Key
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}