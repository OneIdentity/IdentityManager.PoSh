function New-Entity {
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
    [parameter(Mandatory = $true, HelpMessage = 'The tablename of the object to create')]
    [ValidateNotNullOrEmpty()]
    [String] $Type,
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
      $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  Process {
    try {

      # Create entity
      $entityParameters = [VI.DB.Entities.EntityParameters]::new()
      $entityParameters.CreationType = [VI.DB.Entities.EntityCreationType]::Default
      $entity = $src.CreateNewAsync($Type, $entityParameters, $noneToken).GetAwaiter().GetResult()
      $entity = Add-EntityMemberExtension -Entity $entity

      # Set property values
      foreach($property in $Properties.Keys) {
        Set-EntityColumnValue -Entity $Entity -Column $property -Value $Properties[$property]
      }

      # Save entity via UnitOfWork to Database
      if (-Not $Unsaved) {
        $uow = New-UnitOfWork -Session $sessionToUse
        Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $entity
        Save-UnitOfWork -UnitOfWork $uow

        # Reload the entity to allow further updates
        $entity = [VI.DB.Entities.Entity]::ReloadAsync($entity, $sessionToUse, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
        $entity = Add-EntityMemberExtension -Entity $entity
      }

      $entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}