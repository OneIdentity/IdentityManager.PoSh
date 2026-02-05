<#!
.SYNOPSIS
Removes an entity.

.DESCRIPTION
Marks an entity for deletion (optionally without delete delay) and saves it unless
`Unsaved` is specified.

.PARAMETER Session
The session to use.

.PARAMETER Entity
Entity to remove.

.PARAMETER Type
The table name of the object to modify.

.PARAMETER Identity
Load object by UID or XObjectKey.

.PARAMETER Unsaved
Do not automatically save the entity.

.PARAMETER IgnoreDeleteDelay
Delete the entity without delete delay.

.INPUTS
VI.DB.Entities.IEntity

.OUTPUTS
VI.DB.Entities.IEntity

.EXAMPLE
Remove-Entity -Type 'Person' -Identity $uid
#>
function Remove-Entity {
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
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object to modify')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity = '',
    [parameter(Mandatory = $false, HelpMessage = 'If the unsaved switch is specified the entity will not be automatically saved to the database. Intended for bulk operations.')]
    [switch] $Unsaved = $false,
    [parameter(Mandatory = $false, HelpMessage = 'If the IgnoreDeleteDelay switch is specified the entity will be deleted without delete delay.')]
    [switch] $IgnoreDeleteDelay = $false
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

      # Mark entity for removal
      if ($IgnoreDeleteDelay) {
        $Entity.MarkForDeletionWithoutDelay()
      } else {
        $Entity.MarkForDeletion()
      }

      # Save entity via UnitOfWork to database
      if (-Not $Unsaved) {
        [VI.DB.Entities.Entity]::SaveAsync($Entity, $sessionToUse, $noneToken).GetAwaiter().GetResult() | Out-Null
      }

      $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}