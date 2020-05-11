function New-Entity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $true, HelpMessage = 'The tablename of the object to create')]
    [ValidateNotNullOrEmpty()]
    [String] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'The entity properties')]
    [Hashtable] $Properties = @{},
    [parameter(Mandatory = $false, HelpMessage = 'If the unsaved switch is specified the entity will not be automatically saved to the database. Intended for bulk operations.')]
    [switch] $Unsaved = $false
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
    # Create Entity
    $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)
    $entity = $src.CreateNewAsync($Type, [VI.DB.Entities.EntityParameters]::new(), $noneToken).GetAwaiter().GetResult()

    # Set Property Values
    foreach($property in $Properties.Keys) {
      Set-EntityColumnValue -Entity $entity -Column $property -Value $Properties[$property]
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