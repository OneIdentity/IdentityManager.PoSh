function Invoke-EntityMethod {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [ValidateScript({
      try {
        $_.GetType().ImplementedInterfaces.Contains([type]'VI.DB.Entities.ISession')
      }
      catch [System.Management.Automation.PSInvalidCastException] {
        throw [System.Management.Automation.PSInvalidCastException] 'The given value is not a valid session.'
      }
    })]
    $Session = $null,
    [parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity,
    [parameter(Mandatory = $true, HelpMessage = 'The name of the method')]
    [ValidateNotNullOrEmpty()]
    [string] $MethodName,
    [parameter(Mandatory = $false, HelpMessage = 'The method parameters')]
    [object[]] $Parameters = @(),
    [parameter(Mandatory = $false, HelpMessage = 'If the unsaved switch is specified the entity will not be automatically saved to the database. Intended for bulk operations.')]
    [switch] $Unsaved = $false
  )

  Begin {
    try {
      # Determine session to use
      $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
      if ($null -eq $sessionToUse) {
        throw [System.ArgumentNullException] 'Session'
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  Process {
    try {

      # Load object by identity
      $Entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity -Entity $Entity

      # Call the method
      [VI.DB.Entities.Entity]::CallMethodAsync($Entity, $MethodName, $Parameters, $noneToken).GetAwaiter().GetResult() | Out-Null

      # Save entity via UnitOfWork to Database
      if (-Not $Unsaved) {
        $uow = New-UnitOfWork -Session $sessionToUse
        Add-UnitOfWorkEntity -UnitOfWork $uow -Entity $Entity
        Save-UnitOfWork -UnitOfWork $uow
      }

      $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }

  }

  End {
  }
}