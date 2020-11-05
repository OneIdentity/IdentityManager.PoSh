function Get-Event() {
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $false, ValueFromPipeline=$true, HelpMessage = 'Entity to interact with')]
    [VI.DB.Entities.IEntity] $Entity,
    [parameter(Mandatory = $false, HelpMessage = 'The tablename of the object')]
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

      # Load object by identity
      $Entity = Get-EntityByIdentity -Session $sessionToUse -Type $Type -Identity $Identity -Entity $Entity

      if ($null -ne $Entity.PSObject.Members['Table']) {
        $uid = $Entity.Table.Uid
      } else {
        $metaData = [VI.DB.Entities.SessionExtensions]::MetaData($sessionToUse)
        $tableMetaData = $metaData.GetTableAsync($Entity.Tablename, $noneToken).GetAwaiter().GetResult()
        $uid = $tableMetaData.Uid
      }

      $query = [VI.DB.Entities.Query]::From('QBMEvent').Where("UID_DialogTable = '$uid'").Select('EventName')
      $entityCollection = $src.GetCollectionAsync($query, [VI.DB.Entities.EntityCollectionLoadType]::Slim, $noneToken).GetAwaiter().GetResult()

      ForEach ($e in $entityCollection) {
        Write-Host (Get-EntityColumnValue -Entity $e -Column "EventName")
      }
    } catch {
      Resolve-Exception -ExceptionObject $PSitem
    }
  }

  End {
  }
}