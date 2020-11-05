function Set-EntityColumnValue {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The entity to modify')]
    [ValidateNotNull()]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $true, HelpMessage = 'The column to update')]
    [ValidateNotNullOrEmpty()]
    [String] $Column,
    [parameter(Mandatory = $true, HelpMessage = 'The value to set for column')]
    [ValidateNotNullOrEmpty()]
    [Object] $Value,
    [parameter(Mandatory = $false, HelpMessage = 'Switch to toggle if the entity should be saved after change')]
    [switch] $WithSave = $false
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

  Process
  {
    try {
      $metaData = [VI.DB.Entities.SessionExtensions]::MetaData($sessionToUse)
      $tableMetaData = $metaData.GetTableAsync($Entity.Tablename, $noneToken).GetAwaiter().GetResult()

      $valueToSet = $Value

      # If value is an entity and column is UID
      if ($null -ne $Value -and $Value -is [VI.DB.Entities.IEntity] `
        -and $tableMetaData.Columns.IsAvailable($Column) `
        -and ($tableMetaData.Columns | Where-Object { $_.ColumnName -eq $Column }).IsUID)
      {
        $otherTableMetaData = $metaData.GetTableAsync($Value.Tablename, $noneToken).GetAwaiter().GetResult()
        $otherPrimaryKeyColumn = ($otherTableMetaData.Columns | Where-Object { $_.IsPK}).ColumnName
        $valueToSet = Get-EntityColumnValue -Entity $Value -Column $otherPrimaryKeyColumn
      }

      # If value is an entity and column is dynamic FK
      if ($null -ne $Value -and $Value -is [VI.DB.Entities.IEntity] `
        -and $tableMetaData.Columns.IsAvailable($Column) `
        -and ($tableMetaData.Columns | Where-Object { $_.ColumnName -eq $Column }).IsDynamicFK)
      {
        $valueToSet = Get-EntityColumnValue -Entity $Value -Column 'XObjectKey'
      }

      ($Entity).PutValueAsync($Column, $valueToSet, $noneToken).GetAwaiter().GetResult() | Out-Null

      if ($WithSave) {
        $uow = New-UnitOfWork -Session $sessionToUse
        Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $Entity
        Save-UnitOfWork -UnitOfWork $uow
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}