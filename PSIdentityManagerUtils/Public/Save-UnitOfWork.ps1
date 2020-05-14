function Save-UnitOfWork {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The unit of work to commit')]
    [ValidateNotNull()]
    [VI.DB.Entities.IUnitOfWork] $UnitOfWork
  )

  Begin {
  }

  Process {
    ($UnitOfWork).CommitAsync($noneToken).GetAwaiter().GetResult() | Out-Null
    $UnitOfWork.Dispose()
  }

  End {
  }
}