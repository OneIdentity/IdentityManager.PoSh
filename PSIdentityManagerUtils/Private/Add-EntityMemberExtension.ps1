function Add-EntityMemberExtension {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, HelpMessage = 'The entity to extend')]
    [VI.DB.Entities.IEntity] $Entity = $null
  )

  Begin {
  }

  Process {
    try {

      if ($null -ne $Entity) {
        ForEach ($column in $Entity.Columns) {
          $columnName = $column.Columnname
          # Check if there is already a member with that name.
          if ($null -ne $Entity.PSObject.Members[$columnName]) {
            continue
          }

          # Add column as custom property to the entity
          # We have to generate the scripts as string so the column name gets in the string as value instead of a variable.
          Add-Member -InputObject $Entity -MemberType ScriptProperty -Name $columnName `
            -Value (&([Scriptblock]::Create("{Get-EntityColumnValue -Entity `$this -Column '$columnName'}"))) `
            -SecondValue (&([Scriptblock]::Create("{param(`$value) Set-EntityColumnValue -Entity `$this -Column '$columnName' -Value `$value}")))
        }
      }

      return $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}