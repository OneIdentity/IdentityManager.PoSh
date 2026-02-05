<#!
.SYNOPSIS
Commits and disposes a unit of work.

.DESCRIPTION
Commits the provided unit of work and disposes it afterwards.

.PARAMETER UnitOfWork
The unit of work to commit.

.INPUTS
VI.DB.Entities.IUnitOfWork

.OUTPUTS
None

.EXAMPLE
Save-UnitOfWork -UnitOfWork $uow
#>
function Save-UnitOfWork {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = 'The unit of work to commit')]
    [ValidateNotNull()]
    [VI.DB.Entities.IUnitOfWork] $UnitOfWork
  )

  Begin {
  }

  Process {
    try {
      ($UnitOfWork).CommitAsync($noneToken).GetAwaiter().GetResult() | Out-Null
      $UnitOfWork.Dispose()
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}