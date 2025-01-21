function Get-InstalledModule {
    [CmdletBinding()]
    [OutputType([String[]])]
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
      $Session = $null
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
            $resolve = $sessionToUse.Factory.CommonServices.GetType().GetMethod('Resolve')
            $moduleGraphInterface = $resolve.MakeGenericMethod([VI.DB.MetaData.IModuleGraph])
            $moduleGraph = $moduleGraphInterface.Invoke($sessionToUse.Factory.CommonServices, @())

            if ($moduleGraph.Modules -isnot [Array]) {
                @($moduleGraph.Modules)
            } else {
                $moduleGraph.Modules
            }
        } catch {
            Resolve-Exception -ExceptionObject $PSitem
        }
    }
  
    End {
    }
  }
