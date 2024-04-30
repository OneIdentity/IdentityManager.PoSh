function Set-Entity {
  [CmdletBinding()]
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
    [parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = 'Entity to interact with')]
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

      if ($null -eq $Entity) {
        # Load object by identity
        $Entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity -Entity $Entity
      }

      # Set property values
      foreach($property in $Properties.Keys) {
        Set-EntityColumnValue -Entity $Entity -Column $property -Value $Properties[$property]
      }

      # Save entity via UnitOfWork to database
      if (-Not $Unsaved) {
        $uow = New-UnitOfWork -Session $sessionToUse
        Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $Entity
        Save-UnitOfWork -UnitOfWork $uow

        # Reload the entity to allow further updates
        $Entity = [VI.DB.Entities.Entity]::ReloadAsync($Entity, $sessionToUse, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
        $Entity = Add-EntityMemberExtension -Entity $Entity
      }

      return $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}