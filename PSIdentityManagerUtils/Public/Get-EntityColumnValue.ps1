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

  Process
  {
    ($Entity).GetValue($Column).Value
  }

  End {
  }
}