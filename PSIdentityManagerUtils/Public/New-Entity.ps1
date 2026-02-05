<#!
.SYNOPSIS
Creates a new entity.

.DESCRIPTION
Creates a new entity in the specified table, applies property values, and saves
it unless `Unsaved` is specified.

.PARAMETER Session
The session to use.

.PARAMETER Type
The table name of the object to create.

.PARAMETER Properties
Hashtable of column values to set.

.PARAMETER Unsaved
Do not automatically save the entity.

.INPUTS
None

.OUTPUTS
VI.DB.Entities.IEntity

.EXAMPLE
New-Entity -Type 'Person' -Properties @{ Firstname = 'Alex'; Lastname = 'Miller' }
#>
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
        Set-EntityColumnValue -Entity $entity -Column $property -Value $Properties[$property]
      }

      # Save entity via UnitOfWork to Database
      if (-Not $Unsaved) {
        [VI.DB.Entities.Entity]::SaveAsync($entity, $sessionToUse, $noneToken).GetAwaiter().GetResult() | Out-Null

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