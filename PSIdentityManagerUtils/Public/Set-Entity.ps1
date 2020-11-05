function Set-Entity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, ValueFromPipeline=$true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] $Entity = $null,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object to modify')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity,
    [parameter(Mandatory = $false, HelpMessage = 'The entity properties')]
    [Hashtable] $Properties = @{},
    [parameter(Mandatory = $false, HelpMessage = 'If the unsaved switch is specified the entity will not be automatically saved to the database. Intended for bulk operations.')]
    [switch] $Unsaved = $false
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

      # Set property values
      foreach($property in $Properties.Keys) {
        Set-EntityColumnValue -Entity $Entity -Column $property -Value $Properties[$property]
      }

      # Save entity via UnitOfWork to database
      if (-Not $Unsaved) {
        $uow = New-UnitOfWork -Session $sessionToUse
        Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $Entity
        Save-UnitOfWork -UnitOfWork $uow
      }

      return $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}