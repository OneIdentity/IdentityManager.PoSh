<#!
.SYNOPSIS
Gets the row count for a table.

.DESCRIPTION
Returns the number of rows in a table, optionally filtered by a SQL where clause.

.PARAMETER Session
The session to use.

.PARAMETER Name
The table name to query.

.PARAMETER Filter
SQL where clause to filter the result.

.INPUTS
None

.OUTPUTS
System.Int32

.EXAMPLE
Get-TableCount -Name 'Person'

.EXAMPLE
Get-TableCount -Name 'Person' -Filter "IsActive = 1"
#>
function Get-TableCount() {
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
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The tablename of the object')]
    [string] $Name,
    [parameter(Mandatory = $false, Position = 1, HelpMessage = 'Specify a SQL where clause to filter the result')]
    [string] $Filter = ''
  )

  Begin {
    try {
      # Determine session to use
      $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
      if ($null -eq $sessionToUse) {
        throw [System.ArgumentNullException] 'Session'
      }
      $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  Process {
    try {
      $query = [VI.DB.Entities.Query]::From($Name).Where($Filter).SelectCount()
      $result = $src.GetCountAsync($query, $noneToken).GetAwaiter().GetResult()

      $result
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}