function Get-Entity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, HelpMessage = "The tablename of the object to load. This is only needed in case you don't use an XObjectKey")]
    [string] $Type,
    [parameter(Mandatory = $false, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity = '',
    [parameter(Mandatory = $false, HelpMessage = 'Maximum results returned')]
    [int] $ResultSize = 1000,
    [parameter(Mandatory = $false, HelpMessage = 'Specify a SQL where clause to filter the result')]
    [string] $Filter = ''
  )

  Begin {
    # Determine Session to use
    $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
    if($null -eq $sessionToUse) {
      throw [System.ArgumentNullException] 'Session'
    }
  }

  Process {
    $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)

    if (-not [String]::IsNullOrEmpty($Identity)) {
      if (-not ([String]::IsNullOrEmpty($Type))) {
        return Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity
      } else {
        $tableName = ''
        # Try to figure out if we have an XObjectKey
        try {
          $tableName = ([VI.DB.DbObjectKey]::new($Identity)).Tablename
        } catch {
          throw [System.ArgumentException] "Could not create a valid XObjectKey from '$Identity'."
        }

        return Get-EntityByIdentity -Session $sessionToUse -Type $tableName -Identity $Identity
      }

    } else {
      # Query entity collection
      $query = [VI.DB.Entities.Query]::From($Type).Where($Filter).Take($ResultSize).SelectAll()
      $entityCollection = $src.GetCollectionAsync($query, [VI.DB.Entities.EntityCollectionLoadType]::Slim, $noneToken).GetAwaiter().GetResult()

      # Return each entity
      foreach ($entity in $entityCollection) {
        $reloadedEntity = [VI.DB.Entities.Entity]::ReloadAsync($entity, $sessionToUse, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
        Add-EntityMemberExtensions -Entity $reloadedEntity
      }

      # Write warning if there are probably more objects in database
      if ($entityCollection.Count -eq $ResultSize) {
        Write-Warning -Message "There are probably more objects in the database, but the result was limited to $ResultSize entries. To set the limit specify the -ResultSize parameter."
      }
    }
  }

  End {
  }
}