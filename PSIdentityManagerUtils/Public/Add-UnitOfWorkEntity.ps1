<#!
.SYNOPSIS
Adds an entity to a unit of work.

.DESCRIPTION
Calls PutAsync on the provided unit of work to add or update the specified entity.

.PARAMETER UnitOfWork
The unit of work to use for the operation.

.PARAMETER Entity
The entity to add to the unit of work. Accepts input from the pipeline.

.INPUTS
VI.DB.Entities.IEntity

.OUTPUTS
None

.EXAMPLE
Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $entity

.EXAMPLE
$entity | Add-UnitOfWorkEntity -UnitOfWork $uow
#>
function Add-UnitOfWorkEntity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The unit of work to use for set operation')]
    [ValidateNotNull()]
    [VI.DB.Entities.IUnitOfWork] $UnitOfWork,
    [parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, HelpMessage = 'The entity to put')]
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