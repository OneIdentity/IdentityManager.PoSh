function Get-EntityByIdentity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, HelpMessage = 'Internal')]
    [VI.DB.Entities.IEntity] $Entity = $null,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object to load')]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity
  )

  Begin {
    try {
      # Determine session to use
      $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
      if ($null -eq $sessionToUse) {
        throw [System.ArgumentNullException] 'Session'
      }
      $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  Process {
    try {

      # Convenience: If user already specified an entity then use it
      if ($null -eq $Entity) {
        # If there is no entity check identity is not null
        if ([System.String]::IsNullOrEmpty($Identity)) {
          throw 'Identity parameter must be specified when loading an object.'
        }

        # Load Object by UID or XObjectKey
        if ($Identity -like '<Key><T>*</T><P>*</P></Key>') {
          # Load with XObjectKey
          $objectKey = New-Object -TypeName 'VI.DB.DbObjectKey' -ArgumentList $Identity
          $Entity = [VI.DB.EntitySourceExtensions]::GetAsync($src, $objectKey, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
        } else {
          # Check if type was specified and is not null
          if ([System.String]::IsNullOrEmpty($Type)) {
            throw 'Type parameter must be specified when loading an object via UID.'
          }

          # Load with UID
          $Entity = [VI.DB.EntitySourceExtensions]::GetAsync($src, $Type, $Identity, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
        }
      }

      $Entity = Add-EntityMemberExtension -Entity $Entity

      # Return the loaded entity
      return $Entity
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}