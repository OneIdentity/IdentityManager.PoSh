function Add-UnitOfWorkEntity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The unit of work to use for set operation')]
    [ValidateNotNull()]
    [VI.DB.Entities.IUnitOfWork] $UnitOfWork,
    [parameter(Mandatory = $true, HelpMessage = 'The entity to put')]
    [ValidateNotNull()]
    [VI.DB.Entities.IEntity] $Entity
  )

  Begin {
  }

  Process {

    try {
      ($UnitOfWork).PutAsync($Entity, [VI.DB.Entities.PutOptions]::new(), $noneToken).GetAwaiter().GetResult() | Out-Null
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}