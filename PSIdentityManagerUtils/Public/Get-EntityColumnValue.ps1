<#!
.SYNOPSIS
Gets a column value from an entity.

.DESCRIPTION
Returns the value of the specified column on the given entity.

.PARAMETER Entity
The entity to get the value from.

.PARAMETER Column
The column to get.

.INPUTS
VI.DB.Entities.IEntity

.OUTPUTS
System.Object

.EXAMPLE
Get-EntityColumnValue -Entity $entity -Column 'UID_Person'
#>
function Get-EntityColumnValue {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The entity to get the value from')]
    [ValidateNotNull()]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $true, HelpMessage = 'The column to get')]
    [ValidateNotNullOrEmpty()]
    [String] $Column
  )

  Begin {
  }

  Process {
    try {
      $val = ($Entity).GetValue($Column).Value
      $val
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}