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

        # Add column as custom property to the entity
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

        # Add a RELOAD method to the entity / Check if there is already a member with that name.
        if ($null -eq $Entity.PSObject.Members['Reload']) {
          $sb = {
            Param (
              [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
              $Session = $null
            )

            try {
              # Determine session to use
              $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
              if ($null -eq $sessionToUse) {
                throw [System.ArgumentNullException] 'Session'
              }
            } catch {
              Resolve-Exception -ExceptionObject $PSitem
            }

            try {
              $Entity = [VI.DB.Entities.Entity]::ReloadAsync($this, $sessionToUse, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
              $Entity = Add-EntityMemberExtension -Entity $Entity
            } catch {
              Resolve-Exception -ExceptionObject $PSitem
            }

            $Entity
          }

          Add-Member -InputObject $Entity -MemberType ScriptMethod -Name Reload -Value $sb
        }
      }

      $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}