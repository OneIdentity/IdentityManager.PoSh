function Set-TypedWrapperProvider {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, HelpMessage = 'The session to use')]
    [ValidateNotNull()]
    [VI.DB.Entities.ISession] $Session,
    [Parameter(Mandatory = $false, HelpMessage = 'Cmdlet prefix to use for handling multiple connections')]
    [String] $Prefix = '',
    [Parameter(Mandatory = $false, HelpMessage = 'List of modules to skip for function generation')]
    [String[]] $ModulesToSkip
  )

  Begin {
  }

  Process
  {
    $metaData = [VI.DB.Entities.SessionExtensions]::MetaData($Session)
    if ($null -eq $ModulesToSkip)
    {
      $tables = $metaData.GetTablesAsync($noneToken).GetAwaiter().GetResult() | Where-Object { -not $_.IsDeactivated }
    } else {
      $tables = $metaData.GetTablesAsync($noneToken).GetAwaiter().GetResult() | Where-Object { -not $_.IsDeactivated -And (-not $ModulesToSkip.Contains($_.Uid.Substring(0, 3))) }
    }

    $progressCount = 0
    $totalOperationsCount = $tables.Count

    ForEach ($tableProperty in $tables) {
      $funcName = $tableProperty.TableName

      # Do not update progress for every function. It takes to much time.
      if ($progressCount % 10 -eq 0) {
        Write-Progress -Activity 'Generating "Set-" functions' -Status "Function $progressCount of $totalOperationsCount" -CurrentOperation "Set-$Prefix$funcName" -PercentComplete ($progressCount / $totalOperationsCount * 100)
      }
      $progressCount++

      $funcTemplateHeader = @"
function global:Set-$Prefix$funcName() {
  Param (
    [parameter(Mandatory = `$false, ValueFromPipeline=`$true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] `$Entity = `$null,
"@

      ForEach ($column in $tableProperty.Columns) {
        if (-not $column.Enabled) {
          # Skip deactivated columns
          Continue
        }
        $paramName = $column.ColumnName

        if ($column.IsUid) {
          $dateType = "Object"
        } else {
          $dateType = [VI.Base.DbVal]::GetType($column.Type).Name
        }

        $helpText = $null

        if (-not [string]::IsNullOrEmpty($column.Display)) {
          $helpText = $column.Display.Translated -replace "’",  "`'" -replace '"', '`"' -replace '“',  '`"' -replace '”',  '`"' -replace "'", "`'"
        }

        $columnTemplate = @"
`r`n
  [parameter(Mandatory = `$false, HelpMessage = "$helpText")]
  [$dateType] `$$paramName,
"@

        $funcTemplateHeader = $funcTemplateHeader + $columnTemplate
      }
      $funcTemplateHeader = $funcTemplateHeader.Substring(0, $funcTemplateHeader.Length - 1) + ')'

      $funcTemplateFooter = @"
`r`n
  Process {
    `$session = `$Global:imsessions['$Prefix'].Session

    ForEach (`$boundParam in `$PSBoundParameters.GetEnumerator()) {
      # Filter special parameters
      if ('Entity' -eq `$boundParam.Key) {
        Continue
      }
      `$k = `$boundParam.Key
      `$v = `$boundParam.Value

      `$metaData = [VI.DB.Entities.SessionExtensions]::MetaData(`$session)
      `$t = `$metaData.GetTableAsync(`$Entity.Tablename, `$noneToken).GetAwaiter().GetResult()
      if ((`$v.GetType()).Name -eq 'InteractiveProxyEntity' -And (`$t.Columns |Where-Object { `$_.ColumnName -eq `$k }).IsUID) {
        (`$Entity).PutValueAsync(`$k, `$v.GetValue((`$v.Table.Columns |Where-Object { `$_.IsPK}).ColumnName).Value, `$noneToken).GetAwaiter().GetResult() | Out-Null
      } else {
        (`$Entity).PutValueAsync(`$k, `$v, `$noneToken).GetAwaiter().GetResult() | Out-Null
      }
    }

    `$uow = New-UnitOfWork -Session `$session
    Add-UnitOfWorkEntity -UnitOfWork `$uow -Entity `$Entity
    Save-UnitOfWork -UnitOfWork `$uow

    return `$Entity
  }
}
"@

      $funcTemplate = $funcTemplateHeader + $funcTemplateFooter

      try {
        Invoke-Expression $funcTemplate
      } catch {
        $e = $_.Exception
        $msg = $e.Message
        while ($e.InnerException) {
          $e = $e.InnerException
          $msg += "`n" + $e.Message
        }
        write-host $msg
      }
    }
  }

  End {
  }
}