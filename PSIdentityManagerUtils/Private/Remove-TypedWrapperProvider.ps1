function Remove-TypedWrapperProvider {
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
        Write-Progress -Activity 'Generating "Remove-" functions' -Status "Function $progressCount of $totalOperationsCount" -CurrentOperation "Remove-$Prefix$funcName" -PercentComplete ($progressCount / $totalOperationsCount * 100)
      }
      $progressCount++

      $funcTemplateHeader = @"
function global:Remove-$Prefix$funcName() {
  Param (
    [parameter(Mandatory = `$false, ValueFromPipeline=`$true, HelpMessage = 'Entity to remove')]
    [VI.DB.Entities.IEntity] `$Entity = `$null,
    [parameter(Mandatory = `$false, HelpMessage = 'Remove object by UID or XObjectKey')]
    [string] `$Identity = '',
    [parameter(Mandatory = `$false, HelpMessage = 'If the IgnoreDeleteDelay switch is specified the entity will be deleted without delete delay.')]
    [switch] `$IgnoreDeleteDelay = `$false
  )
"@

      $funcTemplateFooter = @"
`r`n
  Process {
    `$session = `$Global:imsessions['$Prefix'].Session
    `$src = [VI.DB.Entities.SessionExtensions]::Source(`$session)

    if (-not [String]::IsNullOrEmpty(`$Identity) -And `$null -eq `$Entity) {
      # Load Object by UID or XObjectKey
      if (`$Identity -like '<Key><T>*</T><P>*</P></Key>') {
        `$objectKey = [VI.DB.DbObjectKey]::new(`$Identity)

        if (-not (`$objectKey.Tablename -eq '$funcName')) {
          throw "The provided XObjectKey `$Identity is not valid for objects of type '$funcName'."
        }

        # Load with XObjectKey
        `$Entity = [VI.DB.EntitySourceExtensions]::GetAsync(`$src, `$objectKey, [VI.DB.Entities.EntityLoadType]::Interactive, `$noneToken).GetAwaiter().GetResult()
      } else {
        # Load with UID
        `$Entity = [VI.DB.EntitySourceExtensions]::GetAsync(`$src, '$funcName', `$Identity, [VI.DB.Entities.EntityLoadType]::Interactive, `$noneToken).GetAwaiter().GetResult()
      }
    }

    if (`$null -eq `$Entity) {
      Throw 'Neither an -Identity nor an -Entity was specified.'
    }

    # Mark entity for removal
    if (`$IgnoreDeleteDelay) {
      `$Entity.MarkForDeletionWithoutDelay()
    }
    else {
      `$Entity.MarkForDeletion()
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