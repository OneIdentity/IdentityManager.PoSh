<#!
.SYNOPSIS
Updates an entity.

.DESCRIPTION
Loads an entity if needed, applies property values, and saves it unless `Unsaved`
is specified. Reloads the entity after save.

.PARAMETER Session
The session to use.

.PARAMETER Entity
Entity to interact with.

.PARAMETER Type
The table name of the object to modify.

.PARAMETER Identity
Load object by UID or XObjectKey.

.PARAMETER Properties
Hashtable of column values to set.

.PARAMETER Unsaved
Do not automatically save the entity.

.INPUTS
VI.DB.Entities.IEntity

.OUTPUTS
VI.DB.Entities.IEntity

.EXAMPLE
Set-Entity -Type 'Person' -Identity $uid -Properties @{ Firstname = 'Alex' }
#>
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
        [VI.DB.Entities.Entity]::SaveAsync($Entity, $sessionToUse, $noneToken).GetAwaiter().GetResult() | Out-Null

        # Reload the entity to allow further updates
        $Entity = [VI.DB.Entities.Entity]::ReloadAsync($Entity, $sessionToUse, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
        $Entity = Add-EntityMemberExtension -Entity $Entity
      }

      $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}