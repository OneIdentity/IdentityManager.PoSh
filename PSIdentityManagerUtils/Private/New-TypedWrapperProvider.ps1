function New-TypedWrapperProvider {
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

        # Do not update progress for every function. It takes to much time.
        if ($progressCount % 10 -eq 0) {
          Write-Progress -Activity 'Generating "New-" functions' -Status "Function $progressCount of $totalOperationsCount" -CurrentOperation "New-$Prefix$funcName" -PercentComplete ($progressCount / $totalOperationsCount * 100)
        }
        $progressCount++

        $funcTemplateHeader = @"
function global:New-$Prefix$funcName() {
  Param (
    [parameter(Mandatory = `$false, HelpMessage = 'If the unsaved switch is specified the entity will not be automatically saved to the database. Intended for bulk operations.')]
    [switch] `$Unsaved = `$false,
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
          $mandatory = $column.MinLen -gt 0 -and (-not ($column.IsPK -and $column.IsUid) -or $tableProperty.IsMNTable)

          if ($mandatory -And $tableProperty.Type -eq 'View')
          {
            # The chance is high, that a view will get some default data
            $mandatory = $false
          }

          $helpText = $null

          if (-not [string]::IsNullOrEmpty($column.Display)) {
            $helpText = $column.Display.Translated -replace "’",  "`'" -replace '"', '`"' -replace '“',  '`"' -replace '”',  '`"' -replace "'", "`'"
          }

          $validateNotNull = ''
          if ($mandatory) {
            $validateNotNull = '[ValidateNotNull()]'
          }

          $columnTemplate = @"
$([Environment]::NewLine)
  [parameter(Mandatory = `$$mandatory, HelpMessage = "$helpText")]
  $validateNotNull
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
      `$cols = @($cols)

      `$properties = @{}
      ForEach (`$boundParam in `$PSBoundParameters.GetEnumerator()) {
        if ((`$cols -contains `$boundParam.Key)) {
          `$properties.Add(`$boundParam.Key, `$boundParam.Value)
        }
      }

      if (`$Unsaved) {
        New-Entity -Session `$session -Type '$funcName' -Properties `$properties -Unsaved
      } else {
        New-Entity -Session `$session -Type '$funcName' -Properties `$properties
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
    $Global:newTypedWrapperProviderDone = $true
    # Make PSScriptAnalyzer happy.
    $Global:newTypedWrapperProviderDone | Out-Null
  }
}