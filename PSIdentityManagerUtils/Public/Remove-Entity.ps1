function Remove-Entity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $true, HelpMessage = 'The tablename of the object to modify')]
    [ValidateNotNullOrEmpty()]
    [string] $Type,
    [parameter(Mandatory = $true, HelpMessage = 'Load object by UID or XObjectKey')]
    [ValidateNotNullOrEmpty()]
    [string] $Identity = '',
    [parameter(Mandatory = $false, HelpMessage = 'If the unsaved switch is specified the entity will not be automatically saved to the database. Intended for bulk operations.')]
    [switch] $Unsaved = $false,
    [parameter(Mandatory = $false, HelpMessage = 'If the IgnoreDeleteDelay switch is specified the entity will be deleted without delete delay.')]
    [switch] $IgnoreDeleteDelay = $false
  )

  Begin {
    # Determine Session to use
    $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
    if($null -eq $sessionToUse) {
      throw [System.ArgumentNullException] 'Session'
    }
  }

  Process
  {
    # Load Object by Identity
    $entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity

    # Mark entity for removal
    if ($IgnoreDeleteDelay) {
      $entity.MarkForDeletionWithoutDelay()
    }
    else {
      $entity.MarkForDeletion()
    }

    # Save Entity via UnitOfWork to Database
    if(-Not $Unsaved) {
      $uow = New-UnitOfWork -Session $sessionToUse
      Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $entity
      Save-UnitOfWork -UnitOfWork $uow
    }

    return $entity
  }

  End {
  }
}