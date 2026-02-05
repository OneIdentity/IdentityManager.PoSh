<#!
.SYNOPSIS
Generates typed Get-* wrapper functions.

.DESCRIPTION
Generates global Get-<Table> functions for each active table, optionally filtered
by modules to include or skip.

.PARAMETER Session
The session to use.

.PARAMETER Prefix
Cmdlet prefix to use for handling multiple connections.

.PARAMETER ModulesToSkip
List of modules to skip for function generation.

.PARAMETER ModulesToAdd
List of modules to add for function generation.

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Get-TypedWrapperProvider -Session $session -Prefix 'Prod'
#>
function Get-TypedWrapperProvider {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, HelpMessage = 'The session to use')]
    [ValidateNotNull()]
    [VI.DB.Entities.ISession] $Session,
    [Parameter(Mandatory = $false, HelpMessage = 'Cmdlet prefix to use for handling multiple connections')]
    [String] $Prefix = '',
    [Parameter(Mandatory = $false, HelpMessage = 'List of modules to skip for function generation')]
    [String[]] $ModulesToSkip,
    [Parameter(Mandatory = $false, HelpMessage = 'List of modules to add for function generation')]
    [String[]] $ModulesToAdd
  )

  Begin {
  }

  Process
  {
    try {

      $metaData = [VI.DB.Entities.SessionExtensions]::MetaData($Session)
      if ($null -eq $ModulesToSkip)
      {
        if ($null -eq $ModulesToAdd) {
          $tables = $metaData.GetTablesAsync($noneToken).GetAwaiter().GetResult() | Where-Object { -not $_.IsDeactivated }
        } else {
          $tables = $metaData.GetTablesAsync($noneToken).GetAwaiter().GetResult() | Where-Object { -not $_.IsDeactivated -And ($ModulesToAdd.Contains($_.Uid.Substring(0, 3))) }
        }
      } else {
        $tables = $metaData.GetTablesAsync($noneToken).GetAwaiter().GetResult() | Where-Object { -not $_.IsDeactivated -And (-not $ModulesToSkip.Contains($_.Uid.Substring(0, 3))) }
      }

      $progressCount = 0
      $totalOperationsCount = $tables.Count

      ForEach ($tableProperty in $tables) {
        $funcName = $tableProperty.TableName
        Write-Debug "Generate Get-$Prefix$funcName"

        # Do not update progress for every function. It takes to much time.
        if ($progressCount % 10 -eq 0) {
          Write-Progress -Activity 'Generating "Get-" functions' -Status "Function $progressCount of $totalOperationsCount" -CurrentOperation "Get-$Prefix$funcName" -PercentComplete ($progressCount / $totalOperationsCount * 100)
        }
        $progressCount++

        $funcTemplateHeader = @"
function global:Get-$Prefix$funcName() {
  Param (
    [parameter(Mandatory = `$false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] `$Identity,
    [parameter(Mandatory = `$false, HelpMessage = 'Maximum results returned')]
    [int] `$ResultSize = 1000,
    [parameter(Mandatory = `$false, HelpMessage = 'Specify a SQL where clause to filter the result')]
    [string] `$FilterClause = '',
"@

        $cols = new-object string[] 0
        ForEach ($column in $tableProperty.Columns) {
          if (-not $column.Enabled) {
            # Skip deactivated columns
            Continue
          }
          $cols += "'" + $column.ColumnName + "',"
          $paramName = $column.ColumnName
          $dateType = [VI.Base.DbVal]::GetType($column.Type).Name

          $helpText = $null

          if (-not [string]::IsNullOrEmpty($column.Display)) {
            $helpText = $column.Display.Translated -replace "’",  "`'" -replace '"', '`"' -replace '“',  '`"' -replace '”',  '`"' -replace "'", "`'"
          }

          $columnTemplate = @"
$([Environment]::NewLine)
  [parameter(Mandatory = `$false, HelpMessage = "$helpText")]
  [$dateType] `$$paramName,
"@

          $funcTemplateHeader = $funcTemplateHeader + $columnTemplate
        }
        $funcTemplateHeader = $funcTemplateHeader.Substring(0, $funcTemplateHeader.Length - 1) + ')'
        $cols[$cols.Length -1 ] = $cols[$cols.Length - 1].Substring(0, $cols[$cols.Length - 1].Length - 1)

        $funcTemplateFooter = @"
$([Environment]::NewLine)
  Process {
    try {
      `$session = `$Global:imsessions['$Prefix'].Session
      `$hadBoundParameters = `$false
      `$cols = @($cols)

      ForEach (`$boundParam in `$PSBoundParameters.GetEnumerator()) {
        # Skip parameter if it is not a column
        if ((`$cols -notcontains `$boundParam.Key)) {
          Continue
        }

        `$FilterClause = `$FilterClause + "{0} = '{1}' and " -f `$boundParam.Key, `$boundParam.Value
        `$hadBoundParameters = `$true
      }

      if (-not [String]::IsNullOrEmpty(`$FilterClause) -And `$hadBoundParameters) {
        `$FilterClause = `$FilterClause.Substring(0, `$FilterClause.Length - 5)
      }

      if (-not [String]::IsNullOrEmpty(`$Identity)) {
        # if the identity is an objectkey, check if it belongs to the table this function is associated with.
        if (`$Identity -like '<Key><T>*</T><P>*</P></Key>') {
          `$objectKey = [VI.DB.DbObjectKey]::new(`$Identity)

          if (-not (`$objectKey.Tablename -eq '$funcName')) {
            throw "The provided XObjectKey `$Identity is not valid for objects of type '$funcName'."
          }
        }

        # Load the object by identity parameter
        Get-Entity -Session `$session -Type '$funcName' -Identity `$Identity -ResultSize `$ResultSize
      }
      else {
        # Load objects by filter
        Get-Entity -Session `$session -Type '$funcName' -Filter `$FilterClause -ResultSize `$ResultSize
      }
    } catch {
      Resolve-Exception -ExceptionObject `$PSitem
    }
  }
}
"@

        $funcTemplate = $funcTemplateHeader + $funcTemplateFooter
        try {
          Invoke-Expression $funcTemplate
        } catch {
          Resolve-Exception -ExceptionObject $PSitem
        }
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
    $Global:getTypedWrapperProviderDone = $true
    # Make PSScriptAnalyzer happy.
    $Global:getTypedWrapperProviderDone |Out-Null
  }
}