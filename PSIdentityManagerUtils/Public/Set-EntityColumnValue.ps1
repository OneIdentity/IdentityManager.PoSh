function Set-EntityColumnValue {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The entity to modify')]
    [ValidateNotNull()]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $true, HelpMessage = 'The column to update')]
    [ValidateNotNullOrEmpty()]
    [String] $Column,
    [parameter(Mandatory = $true, HelpMessage = 'The value to set for column')]
    [ValidateNotNullOrEmpty()]
    [Object] $Value
  )

  Begin {
  }

  Process
  {
    ($Entity).PutValueAsync($Column, $Value, $noneToken).GetAwaiter().GetResult() | Out-Null
  }

  End {
  }
}