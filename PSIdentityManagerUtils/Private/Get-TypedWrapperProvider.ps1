function Get-TypedWrapperProvider {
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

      ForEach ($column in $tableProperty.Columns) {
        if (-not $column.Enabled) {
          # Skip deactivated columns
          Continue
        }
        $paramName = $column.ColumnName
        $dateType = [VI.Base.DbVal]::GetType($column.Type).Name

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
    `$src = [VI.DB.Entities.SessionExtensions]::Source(`$session)
    `$entity = `$null
    `$hadBoundParameters = `$false

    ForEach (`$boundParam in `$PSBoundParameters.GetEnumerator()) {
      # Filter special parameters
      if (('FilterClause' -eq `$boundParam.Key) -Or ('ResultSize' -eq `$boundParam.Key)) {
        Continue
      }
      `$FilterClause = `$FilterClause + "{0} = '{1}' and " -f `$boundParam.Key, `$boundParam.Value
      `$hadBoundParameters = `$true
    }

    if (-not [String]::IsNullOrEmpty(`$Identity)) {
      # Load Object by UID or XObjectKey
      if (`$Identity -like '<Key><T>*</T><P>*</P></Key>') {
        `$objectKey = [VI.DB.DbObjectKey]::new(`$Identity)

        if (-not (`$objectKey.Tablename -eq '$funcName')) {
          throw "The provided XObjectKey `$Identity is not valid for objects of type '$funcName'."
        }

        # Load with XObjectKey
        `$entity = [VI.DB.EntitySourceExtensions]::GetAsync(`$src, `$objectKey, [VI.DB.Entities.EntityLoadType]::Interactive, `$noneToken).GetAwaiter().GetResult()
      } else {
        # Load with UID
        `$entity = [VI.DB.EntitySourceExtensions]::GetAsync(`$src, '$funcName', `$Identity, [VI.DB.Entities.EntityLoadType]::Interactive, `$noneToken).GetAwaiter().GetResult()
      }

      return `$entity
    }

    if (-not [String]::IsNullOrEmpty(`$FilterClause) -And `$hadBoundParameters) {
      `$FilterClause = `$FilterClause.Substring(0, `$FilterClause.Length - 5)
    }

    # Query entity collection
    `$query = [VI.DB.Entities.Query]::From('$funcName').Where(`$FilterClause).Take(`$ResultSize).SelectAll()
    `$entityCollection = `$src.GetCollectionAsync(`$query, [VI.DB.Entities.EntityCollectionLoadType]::Slim, `$noneToken).GetAwaiter().GetResult()

    # Return each entity
    foreach (`$entity in `$entityCollection) {
      [VI.DB.Entities.Entity]::ReloadAsync(`$entity, `$session, [VI.DB.Entities.EntityLoadType]::Interactive, `$noneToken).GetAwaiter().GetResult()
    }

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