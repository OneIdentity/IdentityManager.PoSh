<#!
.SYNOPSIS
Gets available methods for an entity.

.DESCRIPTION
Loads an entity by identity (or uses the provided entity) and returns its object
and customizer methods.

.PARAMETER Session
The session to use.

.PARAMETER Entity
Entity to interact with.

.PARAMETER Type
The table name of the object.

.PARAMETER Identity
Load object by UID or XObjectKey.

.INPUTS
VI.DB.Entities.IEntity

.OUTPUTS
System.Object

.EXAMPLE
Get-EntityMethod -Type 'Person' -Identity $uid
#>
function Get-EntityMethod() {
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

    $entityMethods = New-Object Collections.Generic.List[EntityMethod]
  }

  Process {
    try {

      # Load object by identity
      $Entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity -Entity $Entity

      $objectMethods = [VI.DB.Entities.Entity]::GetEntityMethodsAsync($Entity, $sessionToUse, $null, $noneToken).GetAwaiter().GetResult()

      ForEach ($om in $objectMethods) {
        $entityMethods.Add([EntityMethod]::new('Object', $om.Name, $om.Caption.Original))
      }

      $customizerMethods = [VI.DB.Entities.Entity]::GetMethodsAsync($Entity, $sessionToUse, $noneToken).GetAwaiter().GetResult()
      ForEach ($cm in $customizerMethods) {
        $entityMethods.Add([EntityMethod]::new('Customizer', $cm.Key, $cm.Name))
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

    $entityMethods
  }

  End {
  }
}