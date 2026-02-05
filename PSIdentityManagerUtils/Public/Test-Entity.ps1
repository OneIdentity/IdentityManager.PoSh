<#!
.SYNOPSIS
Tests whether an entity exists.

.DESCRIPTION
Checks whether the specified entity exists by UID or XObjectKey, or verifies that
the provided entity is loaded.

.PARAMETER Session
The session to use.

.PARAMETER Entity
Entity to test for existence.

.PARAMETER Type
The table name of the test object.

.PARAMETER Identity
Test object by UID or XObjectKey.

.INPUTS
VI.DB.Entities.IEntity

.OUTPUTS
System.Boolean

.EXAMPLE
Test-Entity -Type 'Person' -Identity $uid
#>
function Test-Entity {
    [OutputType([bool])]
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
      [parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = 'Entity to test for existence')]
      [VI.DB.Entities.IEntity] $Entity,
      [parameter(Mandatory = $false, HelpMessage = 'The tablename of the test object')]
      [string] $Type,
      [parameter(Mandatory = $false, HelpMessage = 'Test object by UID or XObjectKey')]
      [string] $Identity = ''
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

        $retVal = $false

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
                $retVal = [VI.DB.EntitySourceExtensions]::ExistsAsync($src, $objectKey, $noneToken).GetAwaiter().GetResult()
              } else {
                # Check if type was specified and is not null
                if ([System.String]::IsNullOrEmpty($Type)) {
                  throw 'Type parameter must be specified when loading an object via UID.'
                }
      
                # Load with UID
                $Entity =[VI.DB.EntitySourceExtensions]::GetAsync($src, $Type, $Identity, [VI.DB.Entities.EntityLoadType]::Interactive, $noneToken).GetAwaiter().GetResult()
                if (-not ($null -eq $Entity)) {
                    $Entity = $null
                    $retVal = $true
                }
              }
            } else {
                $retVal = $Entity.IsLoaded
            }
      
          } catch {
            $retVal = $false
          }
  
          return $retVal

    }
  
    End {
    }
  }