function Get-EntityByIdentity {
  [CmdletBinding()]
  Param (
    [parameter(Mandatory = $false, HelpMessage = 'The session to use')]
    [VI.DB.Entities.ISession] $Session = $null,
    [parameter(Mandatory = $true, HelpMessage = 'The tablename of the object to load')]
    [ValidateNotNullOrEmpty()]
    [string] $Type,
    [ValidateNotNullOrEmpty()]
    [parameter(Mandatory = $true, HelpMessage = 'Load object by UID or XObjectKey')]
    [string] $Identity
  )

  Begin {
    # Determine Session to use
    $sessionToUse = Get-IdentityManagerSessionToUse -Session $Session
    if($null -eq $sessionToUse) {
      throw [System.ArgumentNullException] 'Session'
    }
  }

  Process
  {
    $src = [VI.DB.Entities.SessionExtensions]::Source($sessionToUse)

    # Load Object by UID or XObjectKey
    if ($Identity -like '<Key><T>*</T><P>*</P></Key>') {
      # Load with XObjectKey
      $objectKey = New-Object -TypeName 'VI.DB.DbObjectKey' -ArgumentList $Identity
      $entity = [VI.DB.EntitySourceExtensions]::GetAsync($src, $objectKey, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
    } else {
      # Load with UID
      $entity = [VI.DB.EntitySourceExtensions]::GetAsync($src, $Type, $Identity, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
    }

    # Return the loaded entity
    return $entity
  }

  End {
  }
}