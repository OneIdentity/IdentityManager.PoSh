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
      ($Entity).GetValue($Column).Value
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}