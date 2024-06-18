function Remove-TypedWrapperProvider {
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
$([Environment]::NewLine)
  Process {
    try {
      `$session = `$Global:imsessions['$Prefix'].Session

      if (-not [String]::IsNullOrEmpty(`$Identity) -and `$null -eq `$Entity) {
        # if the identity is an objectkey, check it belongs to the table this function is associated with.
        if (`$Identity -like '<Key><T>*</T><P>*</P></Key>') {
          `$objectKey = [VI.DB.DbObjectKey]::new(`$Identity)

          if (-not (`$objectKey.Tablename -eq '$funcName')) {
            throw "The provided XObjectKey `$Identity is not valid for objects of type '$funcName'."
          }
        }
      }

      Remove-Entity -Session `$session -Entity `$Entity -Type '$funcName' -Identity `$Identity -IgnoreDeleteDelay:`$IgnoreDeleteDelay
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
    $Global:removeTypedWrapperProviderDone = $true
    # Make PSScriptAnalyzer happy.
    $Global:removeTypedWrapperProviderDone |Out-Null
  }
}