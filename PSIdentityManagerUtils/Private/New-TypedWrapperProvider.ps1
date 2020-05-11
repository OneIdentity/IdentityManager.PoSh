function New-TypedWrapperProvider {
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
        Write-Progress -Activity 'Generating "New-" functions' -Status "Function $progressCount of $totalOperationsCount" -CurrentOperation "New-$Prefix$funcName" -PercentComplete ($progressCount / $totalOperationsCount * 100)
      }
      $progressCount++

      $funcTemplateHeader = @"
function global:New-$Prefix$funcName() {
  Param (
"@
      ForEach ($column in $tableProperty.Columns) {
        if (-not $column.Enabled) {
          # Skip deactivated columns
          Continue
        }
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
`r`n
  [parameter(Mandatory = `$$mandatory, HelpMessage = "$helpText")]
  $validateNotNull
  [$dateType] `$$paramName,
"@
        $funcTemplateHeader = $funcTemplateHeader + $columnTemplate
      }
      $funcTemplateHeader = $funcTemplateHeader.Substring(0, $funcTemplateHeader.Length - 1) + ')'

      $funcTemplateFooter = @"
`r`n
  Process {
    `$session = `$Global:imsessions['$Prefix'].Session
    `$src = [VI.DB.Entities.SessionExtensions]::Source(`$session)
    `$entity = `$src.CreateNewAsync('$funcName', [VI.DB.Entities.EntityParameters]::new(), `$noneToken).GetAwaiter().GetResult()

    ForEach (`$boundParam in `$PSBoundParameters.GetEnumerator()) {
      `$k = `$boundParam.Key
      `$v = `$boundParam.Value
      (`$Entity).PutValueAsync(`$k, `$v, `$noneToken).GetAwaiter().GetResult() | Out-Null
    }

    `$uow = New-UnitOfWork -Session `$session
    Add-UnitOfWorkEntity -UnitOfWork `$uow -Entity `$entity
    Save-UnitOfWork -UnitOfWork `$uow

  return `$entity
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